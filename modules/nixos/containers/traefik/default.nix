{
  lib,
  pkgs,
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

    host = mkOption {
      type = types.str;
      default = "traefik.local";
      description = "Hostname for Traefik dashboard";
    };

    admin = {
      enable = mkEnableOption (mdDoc "Traefik Proxy Admin panel");

      host = mkOption {
        type = types.str;
        default = "admin.traefik.local";
        description = "Hostname for Traefik Proxy Admin panel";
      };

      dbPassword = mkOption {
        type = types.str;
        default = "traefik_admin_secret";
        description = "PostgreSQL database password for Traefik admin";
      };

      nextAuthSecret = mkOption {
        type = types.str;
        default = "change-this-to-a-random-secret-in-production";
        description = "NextAuth secret for session encryption";
      };
    };

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
  };

  config = mkIf cfg.enable {
    networking.hosts."127.0.0.1" = [cfg.host] ++ optional cfg.admin.enable cfg.admin.host;

    # Auto-configure mkcert for this container's host
    modules.programs.mkcert =
      mkIf (
        (hasAttr "modules" config)
        && (hasAttr "programs" config.modules)
        && (hasAttr "mkcert" config.modules.programs)
        && config.modules.programs.mkcert.enable
      ) {
        domains = [cfg.host] ++ optional cfg.admin.enable cfg.admin.host;
      };

    virtualisation.oci-containers.containers = {
      traefik = let
        mkcertEnabled = config.modules.programs.mkcert.enable;
        certDir = config.modules.programs.mkcert.certDir;
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
          "--label=traefik.enable=true"
          "--label=traefik.http.middlewares.traefik-https-redirect.redirectscheme.scheme=https"
          "--label=traefik.http.middlewares.traefik-https-redirect.redirectscheme.permanent=true"
          "--label=traefik.http.routers.traefik-http.rule=Host(`${cfg.host}`)"
          "--label=traefik.http.routers.traefik-http.entrypoints=web"
          "--label=traefik.http.routers.traefik-http.middlewares=traefik-https-redirect"
          "--label=traefik.http.routers.traefik.rule=Host(`${cfg.host}`)"
          "--label=traefik.http.routers.traefik.entrypoints=websecure"
          "--label=traefik.http.routers.traefik.tls=true"
          "--label=traefik.http.routers.traefik.service=api@internal"
        ];
        volumes =
          [
            "/var/run/docker.sock:/var/run/docker.sock:ro"
            "/var/lib/traefik/dynamic:/etc/traefik/dynamic:ro"
          ]
          ++ optional mkcertEnabled "${certDir}:/custom-certs:ro";
        cmd =
          [
            "--api.insecure=true"
            "--api.dashboard=true"
            "--providers.docker=true"
            "--providers.docker.exposedbydefault=false"
            "--entrypoints.web.address=:80"
            "--entrypoints.websecure.address=:443"
            "--providers.file.directory=/etc/traefik/dynamic"
            "--providers.file.watch=true"
            "--log.level=DEBUG"
            "--accesslog=true"
          ]
          ++ optionals mkcertEnabled [
            "--entrypoints.websecure.http.tls=true"
          ]
          ++ optionals cfg.admin.enable [
            "--providers.http.endpoint=http://traefik-admin:3000/api/traefik/config"
            "--providers.http.pollInterval=10s"
          ];
        log-driver = containerCfg.log-driver;
      };

      traefik-admin-db = mkIf cfg.admin.enable {
        hostname = "traefik-admin-db";
        image = "postgres:latest";
        ports = [
          "127.0.0.1:5433:5432"
        ];
        extraOptions = [
          "--network=local"
        ];
        volumes = [
          "traefik-admin-pgdata:/var/lib/postgresql"
        ];
        environment = {
          POSTGRES_USER = "traefik";
          POSTGRES_PASSWORD = cfg.admin.dbPassword;
          POSTGRES_DB = "traefik_admin";
        };
        log-driver = containerCfg.log-driver;
      };

      traefik-admin = mkIf cfg.admin.enable {
        hostname = "traefik-admin";
        image = "ghcr.io/janhouse/traefik-proxy-admin:latest";
        ports = [
          "127.0.0.1:3001:3000"
        ];
        extraOptions = [
          "--network=local"
          "--label=traefik.enable=true"
          "--label=traefik.http.middlewares.traefik-admin-https-redirect.redirectscheme.scheme=https"
          "--label=traefik.http.middlewares.traefik-admin-https-redirect.redirectscheme.permanent=true"
          "--label=traefik.http.routers.traefik-admin-http.rule=Host(`${cfg.admin.host}`)"
          "--label=traefik.http.routers.traefik-admin-http.entrypoints=web"
          "--label=traefik.http.routers.traefik-admin-http.middlewares=traefik-admin-https-redirect"
          "--label=traefik.http.routers.traefik-admin.rule=Host(`${cfg.admin.host}`)"
          "--label=traefik.http.routers.traefik-admin.entrypoints=websecure"
          "--label=traefik.http.routers.traefik-admin.tls=true"
          "--label=traefik.http.services.traefik-admin.loadbalancer.server.port=3000"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
        environment = {
          DATABASE_URL = "postgresql://traefik:${cfg.admin.dbPassword}@traefik-admin-db:5432/traefik_admin";
          NEXTAUTH_SECRET = cfg.admin.nextAuthSecret;
          NEXTAUTH_URL = "https://${cfg.admin.host}";
        };
        log-driver = containerCfg.log-driver;
      };
    };

    # Generate dynamic TLS configuration
    systemd.tmpfiles.rules = [
      "d /var/lib/traefik 0755 root root -"
      "d /var/lib/traefik/dynamic 0755 root root -"
    ];

    # Write TLS configuration directly to the dynamic directory
    systemd.services.traefik-tls-config = let
      mkcertEnabled = config.modules.programs.mkcert.enable;
    in
      mkIf mkcertEnabled {
        description = "Generate Traefik TLS configuration";
        wantedBy = ["multi-user.target"];
        before = ["${containerCfg.backend}-traefik.service"];
        after = optional mkcertEnabled "mkcert-generate-certs.service";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = let
          customCerts =
            mapAttrsToList (domain: cert: {
              certFile = "/custom-certs/${baseNameOf cert.certFile}";
              keyFile = "/custom-certs/${baseNameOf cert.keyFile}";
            })
            cfg.customCerts;

          # Get all mkcert domains (includes container hosts + additional domains)
          mkcertDomainCerts =
            map (domain: {
              certFile = "/custom-certs/${replaceStrings ["*"] ["wildcard"] domain}.crt";
              keyFile = "/custom-certs/${replaceStrings ["*"] ["wildcard"] domain}.key";
              # Keep the original domain for SNI matching
              domain = domain;
            })
            config.modules.programs.mkcert.domains;

          allCerts = customCerts ++ mkcertDomainCerts;

          # Generate YAML with domains field for proper SNI matching
          certsYaml =
            concatMapStringsSep "\n" (cert:
              "    - certFile: ${cert.certFile}\n      keyFile: ${cert.keyFile}"
            )
            allCerts;
        in ''
          cat > /var/lib/traefik/dynamic/tls.yml <<EOF
          tls:
            certificates:
          ${certsYaml}
            options:
              default:
                minVersion: VersionTLS12
          EOF
        '';
      };

    # Ensure traefik-admin starts after traefik-admin-db
    systemd.services."${containerCfg.backend}-traefik-admin" = mkIf cfg.admin.enable {
      after = ["${containerCfg.backend}-traefik-admin-db.service"];
      requires = ["${containerCfg.backend}-traefik-admin-db.service"];
    };
  };
}
