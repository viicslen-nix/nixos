{
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
        type = types.str;
        default = "docker";
        example = "docker";
        description = ''
          The default backend to use for containers.
        '';
      };

      ssl = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Enable SSL certificate generation for container hosts using mkcert.
          '';
        };

        certDir = mkOption {
          type = types.str;
          default = "/var/lib/traefik/certs";
          description = ''
            Directory to store SSL certificates.
          '';
        };
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

    (mkIf cfg.settings.ssl.enable {
      # Generate SSL certificates for container hosts
      systemd.services.generate-container-certs = let
        containerHosts = unique (flatten [
          (optional config.modules.containers.traefik.enable config.modules.containers.traefik.host)
          (optional config.modules.containers.buggregator.enable config.modules.containers.buggregator.host)
          (optional config.modules.containers.homarr.enable config.modules.containers.homarr.host)
          (optional config.modules.containers.local-ai.enable config.modules.containers.local-ai.host)
          (optional config.modules.containers.meilisearch.enable config.modules.containers.meilisearch.host)
          (optional config.modules.containers.mysql.enable config.modules.containers.mysql.host)
          (optional config.modules.containers.nginx-proxy-manager.enable config.modules.containers.nginx-proxy-manager.host)
          (optional config.modules.containers.portainer.enable config.modules.containers.portainer.host)
          (optional config.modules.containers.postgres.enable config.modules.containers.postgres.host)
          (optional config.modules.containers.qdrant.enable config.modules.containers.qdrant.host)
          (optional config.modules.containers.redis.enable config.modules.containers.redis.host)
          (optional config.modules.containers.soketi.enable config.modules.containers.soketi.host)
        ]);
        hostsArg = concatStringsSep " " containerHosts;
      in {
        description = "Generate SSL certificates for container hosts";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        path = [config.environment.systemPackages];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          mkdir -p ${cfg.settings.ssl.certDir}
          cd ${cfg.settings.ssl.certDir}

          # Generate certificate for all container hosts
          if [ ! -f "containers.crt" ] || [ ! -f "containers.key" ]; then
            mkcert -key-file containers.key -cert-file containers.crt localhost ${hostsArg}
          fi
        '';
      };
    })
  ];
}
