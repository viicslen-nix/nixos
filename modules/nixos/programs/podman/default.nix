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
          environment = {
            systemPackages = with pkgs; [
              dive # look into image layers
              podman-tui # status of containers in the terminal
              podman-compose # start group of containers for dev
              docker-compose # works against the docker-compatible socket below
              docker-credential-helpers # ~/.docker/config.json still names a credsStore
            ];

            sessionVariables = {
              # Default is rootless, a second namespace the oci-containers stack
              # is invisible from — traefik cannot route to a compose project it
              # cannot see. Isolation comes from per-container userns instead.
              CONTAINER_HOST = "unix:///run/podman/podman.sock";
              DOCKER_HOST = "unix:///run/docker.sock";
            };
          };

          virtualisation = {
            containers = {
              enable = true;

              # podman rejects short image names outright; docker implies docker.io.
              # Write the v2 key directly — `registries.search` is deprecated and emits v1.
              registries.settings.unqualified-search-registries = ["docker.io" "quay.io"];

              # `docker compose` is podman shelling out to docker-compose; don't narrate it.
              containersConf.settings.engine.compose_warning_logs = false;

              storage.settings.storage.driver = mkIf (containers.storageDriver != null) containers.storageDriver;
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
        # `--userns=auto` carves each container's range out of the `containers`
        # user's subuid/subgid allocation; without an entry podman fails with
        # "not enough unused IDs in user namespace". Base sits clear of the
        # per-login-user ranges nixpkgs hands out from 100000 up.
        (mkIf (config.modules.containers.settings.userns != null) {
          users.groups.containers = {};
          users.users.containers = {
            isSystemUser = true;
            group = "containers";
            subUidRanges = [
              {
                startUid = 2000000;
                count = 1048576;
              }
            ];
            subGidRanges = [
              {
                startGid = 2000000;
                count = 1048576;
              }
            ];
          };
        })
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
