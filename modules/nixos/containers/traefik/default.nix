{
  lib,
  config,
  ...
}:
with lib; let
  name = "traefik";
  namespace = "containers";

  cfg = config.modules.${namespace}.${name};
  containerCfg = config.modules.containers.settings;
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    customCerts = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          certFile = mkOption {
            type = types.str;
            description = mdDoc "Path to the certificate file";
          };
          keyFile = mkOption {
            type = types.str;
            description = mdDoc "Path to the key file";
          };
        };
      });
      default = {};
      description = mdDoc ''
        Custom certificates for Docker containers.
        The key is the domain name, and the value is the cert/key file paths.
      '';
      example = literalExpression ''
        {
          "myapp.local" = {
            certFile = "/var/lib/traefik/certs/myapp.crt";
            keyFile = "/var/lib/traefik/certs/myapp.key";
          };
        }
      '';
    };

    autoCerts = mkOption {
      type = types.listOf types.str;
      default = [];
      description = mdDoc ''
        List of domains to automatically generate certificates for using mkcert.
        Certificates will be generated and automatically added to Traefik.
      '';
      example = literalExpression ''
        [ "myapp.local" "another.test" "*.example.local" ]
      '';
    };

    certDir = mkOption {
      type = types.str;
      default = "/var/lib/traefik/certs";
      description = mdDoc "Directory to watch for custom certificates";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      traefik = let
        sslEnabled = containerCfg.ssl.enable;
        certDir = containerCfg.ssl.certDir;
      in {
        hostname = "traefik";
        image = "traefik:latest";
        ports = [
          "80:80"
          "443:443"
          "127.0.0.1:8080:8080"
        ];
        extraOptions = [
          "--network=local"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
          "traefik-data:/etc/traefik"
          "${cfg.certDir}:/custom-certs:ro"
        ] ++ optional sslEnabled "${certDir}:/certs:ro";
        cmd = [
          "--api.insecure=true"
          "--providers.docker=true"
          "--providers.docker.exposedbydefault=false"
          "--entrypoints.web.address=:80"
          "--entrypoints.websecure.address=:443"
          "--providers.file.directory=/etc/traefik/dynamic"
          "--providers.file.watch=true"
        ] ++ optionals sslEnabled [
          "--entrypoints.websecure.http.tls=true"
        ];
        log-driver = containerCfg.log-driver;
      };
    };

    # Create Traefik directories
    systemd.tmpfiles.rules = [
      "d /var/lib/traefik 0755 root root -"
      "d /var/lib/traefik/dynamic 0755 root root -"
      "d ${cfg.certDir} 0755 root root -"
    ];

    # Generate dynamic TLS configuration
    environment.etc."traefik/dynamic/tls.yml" = let
      containerCert = optionalAttrs containerCfg.ssl.enable {
        certFile = "/certs/containers.crt";
        keyFile = "/certs/containers.key";
      };

      customCerts = mapAttrsToList (domain: cert: {
        certFile = "/custom-certs/${baseNameOf cert.certFile}";
        keyFile = "/custom-certs/${baseNameOf cert.keyFile}";
      }) cfg.customCerts;

      autoCerts = map (domain: {
        certFile = "/custom-certs/${replaceStrings ["*"] ["wildcard"] domain}.crt";
        keyFile = "/custom-certs/${replaceStrings ["*"] ["wildcard"] domain}.key";
      }) cfg.autoCerts;

      allCerts = optional containerCfg.ssl.enable containerCert ++ customCerts ++ autoCerts;
    in {
      text = generators.toYAML {} {
        tls = {
          certificates = allCerts;
        };
      };
    };

    # Generate auto certificates with mkcert
    systemd.services.traefik-auto-certs = mkIf (cfg.autoCerts != []) {
      description = "Generate auto certificates for Traefik";
      wantedBy = [ "multi-user.target" ];
      before = [ "${containerCfg.backend}-traefik.service" ];
      path = [ config.environment.systemPackages ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p ${cfg.certDir}
        cd ${cfg.certDir}

        ${concatStringsSep "\n" (map (domain: let
          safeName = replaceStrings ["*"] ["wildcard"] domain;
        in ''
          if [ ! -f "${safeName}.crt" ] || [ ! -f "${safeName}.key" ]; then
            mkcert -key-file ${safeName}.key -cert-file ${safeName}.crt ${domain}
          fi
        '') cfg.autoCerts)}
      '';
    };

    # Copy custom certificates to the cert directory
    systemd.services.traefik-custom-certs = mkIf (cfg.customCerts != {}) {
      description = "Copy custom certificates for Traefik";
      wantedBy = [ "multi-user.target" ];
      before = [ "${containerCfg.backend}-traefik.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = concatStringsSep "\n" (
        mapAttrsToList (domain: cert: ''
          cp ${cert.certFile} ${cfg.certDir}/
          cp ${cert.keyFile} ${cfg.certDir}/
        '') cfg.customCerts
      );
    };
  };
}
