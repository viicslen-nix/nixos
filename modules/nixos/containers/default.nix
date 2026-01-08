{
  lib,
  pkgs,
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
        type = types.str;
        default = "docker";
        example = "docker";
        description = ''
          The default backend to use for containers.
        '';
      };
    };
  };

  imports = [
    ./buggregator
    ./homarr
    ./local-ai
    ./meilisearch
    ./mysql
    ./nginx-proxy-manager
    ./portainer
    ./postgres
    ./qdrant
    ./redis
    ./soketi
    ./traefik
  ];

  config = mkMerge [
    {
      # Create external container network
      systemd.services.init-container-network = {
        description = "Create local container network";
        after =
          if cfg.settings.backend == "docker"
          then ["docker.service"]
          else ["podman.service"];
        requires =
          if cfg.settings.backend == "docker"
          then ["docker.service"]
          else ["podman.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig.Type = "oneshot";
        script =
          if cfg.settings.backend == "docker"
          then ''
            ${config.virtualisation.docker.package}/bin/docker network inspect local >/dev/null 2>&1 || \
            ${config.virtualisation.docker.package}/bin/docker network create local
          ''
          else ''
            ${config.virtualisation.podman.package}/bin/podman network inspect local >/dev/null 2>&1 || \
            ${config.virtualisation.podman.package}/bin/podman network create local
          '';
      };

      virtualisation.oci-containers.backend = cfg.settings.backend;
    }
  ];
}
