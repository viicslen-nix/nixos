{
  flake.modules.nixos.docker = {
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
      name = "docker";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};

      # Engine-agnostic knobs live once, on the containers module.
      containers = config.modules.containers.settings;
    in {
      options.modules.${namespace}.${name} = {
        enable = mkOption {
          type = types.bool;
          default = containers.backend == "docker";
          description = "Enable docker. Follows `modules.containers.settings.backend`.";
        };

        networkInterface = mkOption {
          type = types.str;
          default = "docker0";
          description = "The network interface to allow in the firewall";
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          environment = {
            systemPackages = with pkgs; [
              docker-credential-helpers
              docker-buildx
            ];

            sessionVariables = {
              COMPOSE_BAKE = "true";
            };
          };

          virtualisation = {
            docker = {
              enable = true;
              autoPrune.enable = true;
              # docker calls the default driver `overlay2`; podman calls it `overlay`.
              storageDriver =
                if containers.storageDriver == null
                then "overlay2"
                else containers.storageDriver;
              package = pkgs.docker.override {
                buildxSupport = true;
              };
            };

            podman.enable = false;

            oci-containers.backend = "docker";
          };

          users.users = lib.genAttrs (attrNames users) (_user: {
            extraGroups = ["docker"];
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
          directories = [".docker"];
        })
        (persistence.mkNixosPersistence {
          inherit config;
          directories = [
            "/var/lib/docker"
          ];
        })
      ]);
    };
}
