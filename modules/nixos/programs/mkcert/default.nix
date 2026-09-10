{
  flake.modules.nixos.mkcert = {
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
      caRoot = "${cfg.certDir}/ca";
      certutil = "${pkgs.nssTools}/bin/certutil";
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);
        rootCA = {
          enable = mkEnableOption "a shared, pre-generated mkcert root CA";

          # The cert is public: keep it plain in the repo so it can also feed the
          # build-time system bundle. Only the key is a secret.
          certPath = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = mdDoc "Store path of the shared rootCA.pem (a plain file in the repo).";
            example = literalExpression "./secrets/mkcert/rootCA.pem";
          };

          keyPath = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = mdDoc "Runtime path of the shared rootCA-key.pem (an agenix secret).";
            example = literalExpression "config.age.secrets.mkcert-rootCA-key.path";
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
          assertions = [
            {
              assertion = cfg.rootCA.enable -> (cfg.rootCA.certPath != null && cfg.rootCA.keyPath != null);
              message = "modules.programs.mkcert.rootCA needs both certPath and keyPath.";
            }
          ];

          environment.systemPackages = [
            pkgs.mkcert
            pkgs.nssTools
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

          security.pki.certificateFiles = mkIf cfg.rootCA.enable [cfg.rootCA.certPath];

          # Every mkcert call — plain, `mkcert-dev`, `generate-cert` — signs with the shared CA.
          environment.sessionVariables.CAROOT = mkIf cfg.rootCA.enable caRoot;

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
            environment.CAROOT = caRoot;
            script = ''
              mkdir -p ${cfg.certDir}
              cd ${cfg.certDir}

              ${optionalString cfg.rootCA.enable ''
                # mkcert wants cert and key side by side under CAROOT.
                install -Dm644 ${cfg.rootCA.certPath} ${caRoot}/rootCA.pem
                install -Dm640 -g users ${cfg.rootCA.keyPath} ${caRoot}/rootCA-key.pem
              ''}

              # Generate certificates for each domain
              ${concatMapStringsSep "\n" (domain: ''
                  echo "Generating certificate for ${domain}..."
                  mkcert -key-file ${replaceStrings ["*"] ["wildcard"] domain}.key -cert-file ${replaceStrings ["*"] ["wildcard"] domain}.crt "${domain}"
                '')
                cfg.domains}
            '';
          };
        }

        # Chromium and Electron ignore /etc/ssl on Linux; they trust ~/.pki/nssdb.
        (mkIf (builtins.hasAttr "home-manager" options) {
          home-manager.users = genAttrs (attrNames users) (_: {lib, ...}: {
            home.activation.mkcertNss = lib.hm.dag.entryAfter ["writeBoundary"] ''
              ca=${
              if cfg.rootCA.enable
              then cfg.rootCA.certPath
              else "${caRoot}/rootCA.pem"
            }
              db="$HOME/.pki/nssdb"
              if [ -r "$ca" ]; then
                mkdir -p "$db"
                [ -f "$db/cert9.db" ] || run ${certutil} -N --empty-password -d "sql:$db"
                run ${certutil} -D -d "sql:$db" -n "mkcert (${caRoot})" 2>/dev/null || true
                run ${certutil} -A -d "sql:$db" -t C,, -n "mkcert (${caRoot})" -i "$ca"
              fi
            '';
          });
        })

        (persistence.mkHmPersistence {
          inherit config options;
          users = attrNames users;
          share = ["mkcert"];
        })
      ]);
    };
}
