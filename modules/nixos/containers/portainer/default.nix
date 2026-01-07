{
  lib,
  config,
  ...
}:
with lib; let
  name = "portainer";
  namespace = "containers";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    host = mkOption {
      type = types.str;
      default = "portainer.local";
      description = "Hostname for Portainer";
    };
  };

  config = mkIf cfg.enable {
    networking.hosts."127.0.0.1" = [cfg.host];

    virtualisation.oci-containers.containers = {
      portainer = {
        hostname = "portainer";
        image = "portainer/portainer-ee:latest";
        ports = [
          # "127.0.0.1:8000:8000"
          "127.0.0.1:9443:9443"
        ];
        volumes = [
          "portainer:/data"
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
        extraOptions = [
          "--network=local"
          "--label=traefik.enable=true"
          "--label=traefik.http.routers.portainer.rule=Host(`${cfg.host}`)"
          "--label=traefik.http.routers.portainer.entrypoints=websecure"
          "--label=traefik.http.routers.portainer.tls=true"
          "--label=traefik.http.services.portainer.loadbalancer.server.port=9443"
          "--label=traefik.http.services.portainer.loadbalancer.server.scheme=https"
        ];
        log-driver = config.modules.containers.settings.log-driver;
      };
    };
  };
}
