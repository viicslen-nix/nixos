{
  lib,
  pkgs,
  users,
  config,
  options,
  inputs,
  ...
}:
with lib;
with inputs.self.lib; let
  name = "mkcert";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
    rootCA = {
      enable = mkEnableOption "Enable mkcert root CA certificate.";
      path = mkOption {
        type = types.str;
        default = ".local/share/mkcert/rootCA.pem";
        description = ''
          Location of the root CA relative to the user's home directory.
        '';
      };
    };

    certDir = mkOption {
      type = types.str;
      default = "/var/lib/mkcert";
      description = mdDoc "Directory to store generated certificates";
    };

    domains = mkOption {
      type = types.listOf types.str;
      default = [];
      description = mdDoc ''
        List of domains to generate certificates for.
        Supports wildcards (e.g., "*.example.com").
      '';
      example = literalExpression ''
        [ "app.local" "*.example.test" "api.dev" ]
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [
        pkgs.mkcert
        pkgs.nss
        (pkgs.writeShellScriptBin "mkcert-dev" ''
          domain=$1

          if [ -z "$2" ]; then
            # If the second argument is empty, set it to the current working directory
            directory=$(pwd)
          else
            # Use the provided second argument
            directory="$2"
          fi

          # Generate certificate
          ${pkgs.mkcert}/bin/mkcert -key-file "''${directory}/''${domain}.key" -cert-file "''${directory}/''${domain}.crt" "localhost" "''${domain}" "*.''${domain}"
        '')
      ];

      security.pki.certificateFiles = mkIf (cfg.domains != []) [
        "${cfg.certDir}/ca/rootCA.pem"
      ];

      systemd.tmpfiles.rules = mkIf (cfg.domains != []) [
        "d ${cfg.certDir} 0755 root root -"
        "d ${cfg.certDir}/ca 0755 root root -"
      ];

      systemd.services.mkcert-generate-certs = mkIf (cfg.domains != []) {
        description = "Generate SSL certificates using mkcert";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        path = with pkgs; [
          mkcert
          nss.tools
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        environment = {
          CAROOT = "${cfg.certDir}/ca";
        };
        script = ''
          mkdir -p ${cfg.certDir}/ca
          cd ${cfg.certDir}

          # Generate certificates for each domain
          ${concatMapStringsSep "\n" (domain: ''
              echo "Generating certificate for ${domain}..."
              mkcert -key-file ${replaceStrings ["*"] ["wildcard"] domain}.key -cert-file ${replaceStrings ["*"] ["wildcard"] domain}.crt "${domain}"
            '')
            cfg.domains}
        '';
      };
    }
    (mkNixosPersistence {
      inherit config options;
      users = attrNames users;
      share = ["mkcert"];
    })
  ]);
}
