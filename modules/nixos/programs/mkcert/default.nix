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

      certPath = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = mdDoc ''
          Path to a pre-generated mkcert root CA certificate (rootCA.pem).
          This should point to a file in your repository (can be age/sops encrypted).
          If null, the CA must already exist in certDir/ca/rootCA.pem.
        '';
        example = literalExpression ''
          ./secrets/mkcert-rootCA.pem
        '';
      };

      keyPath = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = mdDoc ''
          Path to a pre-generated mkcert root CA key (rootCA-key.pem).
          This should point to a file in your repository (can be age/sops encrypted).
          If null, the key must already exist in certDir/ca/rootCA-key.pem.
        '';
        example = literalExpression ''
          ./secrets/mkcert-rootCA-key.pem
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

      # Only add to system trust store if rootCA is enabled and cert path is provided
      security.pki.certificateFiles = mkIf (cfg.rootCA.enable && cfg.rootCA.certPath != null) [
        cfg.rootCA.certPath
      ];

      systemd.tmpfiles.rules = mkIf (cfg.domains != []) [
        "d ${cfg.certDir} 0755 root root -"
      ];

      systemd.services.mkcert-generate-certs = mkIf (cfg.domains != []) {
        description = "Generate SSL certificates using mkcert";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        path = with pkgs; [
          mkcert
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        environment = mkMerge [
          (mkIf (cfg.rootCA.enable && cfg.rootCA.certPath != null) {
            CAROOT = dirOf cfg.rootCA.certPath;
          })
          (mkIf (!cfg.rootCA.enable || cfg.rootCA.certPath == null) {
            CAROOT = "${cfg.certDir}/ca";
          })
        ];
        script = ''
          mkdir -p ${cfg.certDir}
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
    (persistence.mkHmPersistence {
      inherit config options;
      users = attrNames users;
      share = ["mkcert"];
    })
  ]);
}
