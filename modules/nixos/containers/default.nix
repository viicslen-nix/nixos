{
  flake.modules.nixos.containers = {
    lib,
    config,
    ...
  }:
    with lib; let
      name = "containers";
      namespace = "modules";

      cfg = config.${namespace}.${name};
    in {
      options.${namespace}.${name} = {
        settings = {
          log-driver = mkOption {
            type = types.str;
            default = "journald";
            example = "journald";
            description = ''
              The default log driver to use for containers.
            '';
          };

          backend = mkOption {
            type = types.enum ["docker" "podman"];
            default = "docker";
            example = "podman";
            description = ''
              The default backend to use for containers.
            '';
          };

          nvidiaSupport = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Enable support for NVIDIA GPUs in the container backend.
            '';
          };

          storageDriver = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "btrfs";
            description = ''
              The storage driver to use. `null` leaves each backend on its own
              default — `overlay2` for docker, `overlay` for podman — since the
              two name the same driver differently.
            '';
          };

          allowTcpPorts = mkOption {
            type = types.listOf types.int;
            default = [80 443];
            description = ''
              The TCP ports the container backend opens in the firewall.
            '';
          };
        };
      };

      # The container modules in this directory are discovered automatically by
      # parts/modules.nix — no import list to maintain.

      config = mkMerge [
        {
          # Create external container network
          systemd.services.init-container-network = {
            description = "Create local container network";
            # podman is daemonless — only docker needs its service up first.
            after = optional (cfg.settings.backend == "docker") "docker.service";
            requires = optional (cfg.settings.backend == "docker") "docker.service";
            wantedBy = ["multi-user.target"];
            serviceConfig.Type = "oneshot";
            script = let
              bin =
                if cfg.settings.backend == "docker"
                then "${config.virtualisation.docker.package}/bin/docker"
                else "${config.virtualisation.podman.package}/bin/podman";
            in ''
              ${bin} network inspect local >/dev/null 2>&1 || ${bin} network create local
            '';
          };

          virtualisation.oci-containers.backend = cfg.settings.backend;
        }
      ];
    };
}
