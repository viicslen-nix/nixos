{
  flake.modules.nixos.podman = {
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
      name = "podman";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};

      # Engine-agnostic knobs live once, on the containers module.
      containers = config.modules.containers.settings;
    in {
      options.modules.${namespace}.${name} = {
        enable = mkOption {
          type = types.bool;
          default = containers.backend == "podman";
          description = "Enable podman. Follows `modules.containers.settings.backend`.";
        };

        networkInterface = mkOption {
          type = types.str;
          default = "podman0";
          description = "The network interface to allow in the firewall";
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          environment.systemPackages = with pkgs; [
            dive # look into image layers
            podman-tui # status of containers in the terminal
            podman-compose # start group of containers for dev
            docker-compose # works against the docker-compatible socket below
          ];

          virtualisation = {
            containers = {
              enable = true;
              # Defining `settings` at all drops the upstream default table, so restate the paths.
              storage.settings = mkIf (containers.storageDriver != null) {
                storage = {
                  driver = containers.storageDriver;
                  graphroot = "/var/lib/containers/storage";
                  runroot = "/run/containers/storage";
                };
              };
            };

            docker.enable = false;

            podman = {
              enable = true;
              autoPrune.enable = true;

              # `docker` as an alias for podman, to use it as a drop-in replacement
              dockerCompat = true;

              # /run/docker.sock, which the containers bind-mounting it depend on
              dockerSocket.enable = true;

              # Required for containers under podman-compose to be able to talk to each other.
              defaultNetwork.settings.dns_enabled = true;
            };

            oci-containers.backend = "podman";
          };

          users.users = lib.genAttrs (attrNames users) (_user: {
            extraGroups = ["podman"];
          });

          networking = {
            firewall.trustedInterfaces = [cfg.networkInterface];
            firewall.allowedTCPPorts = containers.allowTcpPorts;

            hosts."127.0.0.1" = [
              "kubernetes.docker.internal"
              "host.docker.internal"
            ];
          };

          hardware.nvidia-container-toolkit.enable = containers.nvidiaSupport;
        }
        (persistence.mkHmPersistence {
          inherit config options;
          users = attrNames users;
          share = ["containers"];
        })
        (persistence.mkNixosPersistence {
          inherit config;
          directories = [
            "/var/lib/containers"
          ];
        })
      ]);
    };
}
