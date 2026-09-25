{
  flake.modules.nixos.cliproxyapi = {
    lib,
    pkgs,
    config,
    inputs,
    ...
  }:
    with lib; let
      inherit (inputs.self.lib.containers) mkHostOption mkMkcertDomains;
      inherit (inputs.self.lib) persistence;

      name = "cliproxyapi";
      namespace = "services";

      cfg = config.modules.${namespace}.${name};

      traefikEnabled = attrByPath ["modules" "containers" "traefik" "enable"] false config;
      backend = attrByPath ["modules" "containers" "settings" "backend"] "podman" config;

      # The `local` network's bridge is `podmanN` under podman and `br-<id>` under docker.
      # `+` is iptables' wildcard; nftables would need `*`.
      bridgeInterface =
        if backend == "docker"
        then "br-+"
        else "podman+";

      traefikConfig = (pkgs.formats.yaml {}).generate "cliproxyapi-traefik.yml" {
        http = {
          routers = {
            "${name}-http" = {
              rule = "Host(`${cfg.host}`)";
              entryPoints = ["web"];
              middlewares = ["${name}-https-redirect"];
              service = name;
            };
            ${name} = {
              rule = "Host(`${cfg.host}`)";
              entryPoints = ["websecure"];
              tls = {};
              service = name;
            };
          };
          middlewares."${name}-https-redirect".redirectScheme = {
            scheme = "https";
            permanent = true;
          };
          # Resolves to the `local` bridge gateway, so the service must listen beyond loopback.
          services.${name}.loadBalancer.servers = [{url = "http://host.containers.internal:${toString cfg.port}";}];
        };
      };
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        host = mkHostOption "cliproxy.local" "CLIProxyAPI";

        port = mkOption {
          type = types.port;
          default = 8317;
          description = "Port CLIProxyAPI listens on.";
        };

        apiKeyFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "File holding the API key clients must send.";
        };

        managementKeyFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "File holding the Management API key. Null disables the Management API and its panel.";
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          services.cliproxyapi = {
            enable = true;
            settings =
              {
                host = "";
                inherit (cfg) port;
              }
              // optionalAttrs (cfg.apiKeyFile != null) {
                api-keys = [{_secret = cfg.apiKeyFile;}];
              }
              // optionalAttrs (cfg.managementKeyFile != null) {
                remote-management = {
                  # Traefik reaches it from the container bridge, which counts as remote.
                  allow-remote = true;
                  secret-key._secret = cfg.managementKeyFile;
                };
              };
          };

          # Binds all interfaces for Traefik's sake; only loopback and the container bridge may connect.
          networking.firewall.interfaces.${bridgeInterface}.allowedTCPPorts = mkIf traefikEnabled [cfg.port];

          environment.systemPackages = [config.services.cliproxyapi.package];
        }
        (mkIf traefikEnabled {
          networking.hosts."127.0.0.1" = [cfg.host];

          modules.programs.mkcert = mkMkcertDomains config [cfg.host];

          # Copied, not symlinked: the traefik container has no /nix/store to follow a link into.
          systemd.tmpfiles.settings.cliproxyapi-traefik."/var/lib/traefik/dynamic/cliproxyapi.yml"."C+" = {
            argument = "${traefikConfig}";
          };
        })
        (persistence.mkNixosPersistence {
          inherit config;
          directories = ["/var/lib/cliproxyapi"];
        })
      ]);
    };
}
