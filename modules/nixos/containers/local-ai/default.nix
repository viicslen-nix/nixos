{
  lib,
  config,
  ...
}:
with lib; let
  name = "local-ai";
  namespace = "containers";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    host = mkOption {
      type = types.str;
      default = "ai.local";
      description = "Hostname for Local AI";
    };
  };

  config = mkIf cfg.enable {
    networking.hosts."127.0.0.1" = [cfg.host];

    virtualisation.oci-containers.containers = {
      local-ai = {
        hostname = "local-ai";
        image = "localai/localai:latest-aio-gpu-nvidia-cuda-12";
        volumes = [
          "localai-models:/build/models"
        ];
        environment = {
          DEBUG = "true";
        };
        extraOptions = [
          "--network=local"
          "--device=nvidia.com/gpu=all"
          "--label=traefik.enable=true"
          "--label=traefik.http.routers.localai.rule=Host(`${cfg.host}`)"
          "--label=traefik.http.routers.localai.entrypoints=websecure"
          "--label=traefik.http.routers.localai.tls=true"
          "--label=traefik.http.services.localai.loadbalancer.server.port=8080"
        ];
        log-driver = config.modules.containers.settings.log-driver;
      };
    };
  };
}
