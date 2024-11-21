{
  lib,
  config,
  ...
}:
with lib; let
  name = "containers";
  namespace = "features";

  cfg = config.${namespace}.${name};
in {
  options.${namespace}.${name} = {
    portainer = mkEnableOption (mdDoc "Portainer");
    mysql = mkEnableOption (mdDoc "MySQL");
    redis = mkEnableOption (mdDoc "Redis");
    soketi = mkEnableOption (mdDoc "Soketi");
    meilisearch = mkEnableOption (mdDoc "Meilisearch");
    buggregator = mkEnableOption (mdDoc "Buggregator");
    nginx-proxy-manager = mkEnableOption (mdDoc "Nginx Proxy Manager");
    local-ai = mkEnableOption (mdDoc "Local AI");
  };

  config = {
    virtualisation.oci-containers.containers = {
      portainer = mkIf cfg.portainer {
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
        ];
      };

      mysql = mkIf cfg.mysql {
        hostname = "mysql";
        image = "percona/percona-server:latest";
        ports = [
          "127.0.0.1:3306:3306"
        ];
        volumes = [
          "percona-mysql:/var/lib/mysql"
        ];
        extraOptions = [
          "--network=local"
        ];
        environment = {
          MYSQL_ROOT_PASSWORD = "secret";
        };
      };

      redis = mkIf cfg.redis {
        hostname = "redis";
        image = "redis:alpine";
        ports = [
          "127.0.0.1:6379:6379"
        ];
        volumes = [
          "redis:/data"
        ];
        extraOptions = [
          "--network=local"
        ];
      };

      meilisearch = mkIf cfg.meilisearch {
        hostname = "meilisearch";
        image = "getmeili/meilisearch:latest";
        ports = [
          "127.0.0.1:7700:7700"
        ];
        volumes = [
          "meiliseach:/meili_data"
        ];
        extraOptions = [
          "--network=local"
        ];
        environment = {
          MEILI_NO_ANALYTICS = "false";
        };
      };

      soketi = mkIf cfg.soketi {
        hostname = "soketi";
        image = "quay.io/soketi/soketi:latest-16-alpine";
        ports = [
          "127.0.0.1:6001:6001"
          "127.0.0.1:9601:9601"
        ];
        extraOptions = [
          "--network=local"
        ];
        environment = {
          SOKETI_DEBUG = "1";
          SOKETI_METRICS_SERVER_PORT = "9601";
          SOKETI_DEFAULT_APP_ID = "soketi";
          SOKETI_DEFAULT_APP_KEY = "soketi";
          SOKETI_DEFAULT_APP_SECRET = "soketi";
        };
      };

      buggregator = mkIf cfg.buggregator {
        hostname = "buggregator";
        image = "ghcr.io/buggregator/server:latest";
        ports = [
          "127.0.0.1:8000:8000"
          "127.0.0.1:1025:1025"
          "127.0.0.1:9912:9912"
          "127.0.0.1:9913:9913"
        ];
        extraOptions = [
          "--network=local"
        ];
      };

      nginx-proxy-manager = mkIf cfg.nginx-proxy-manager {
        hostname = "npm";
        image = "jc21/nginx-proxy-manager:latest";
        ports = [
          "127.0.0.1:80:80"
          "127.0.0.1:443:443"
          "127.0.0.1:81:81"
        ];
        volumes = [
          "nginx-proxy-manager:/data"
          "letsencrypt:/etc/letsencrypt"
        ];
        extraOptions = [
          "--network=local"
        ];
      };

      local-ai = mkIf cfg.local-ai {
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
        ];
      };
    };
  };
}
