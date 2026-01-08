{
  lib,
  config,
  ...
}:
with lib; let
  name = "soketi";
  namespace = "containers";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    host = mkOption {
      type = types.str;
      default = "soketi.local";
      description = "Hostname for Soketi";
    };
  };

  config = mkIf cfg.enable {
    networking.hosts."127.0.0.1" = [cfg.host];

    # Auto-configure mkcert for this container's host
    modules.programs.mkcert =
      mkIf (
        (hasAttr "modules" config)
        && (hasAttr "programs" config.modules)
        && (hasAttr "mkcert" config.modules.programs)
        && config.modules.programs.mkcert.enable
      ) {
        domains = [cfg.host];
      };

    virtualisation.oci-containers.containers = {
      soketi = {
        hostname = "soketi";
        image = "quay.io/soketi/soketi:latest-16-alpine";
        ports = [
          "127.0.0.1:6001:6001"
          "127.0.0.1:9601:9601"
        ];
        extraOptions = [
          "--network=local"
          "--label=traefik.enable=true"
          "--label=traefik.http.middlewares.soketi-https-redirect.redirectscheme.scheme=https"
          "--label=traefik.http.middlewares.soketi-https-redirect.redirectscheme.permanent=true"
          "--label=traefik.http.routers.soketi-http.rule=Host(`${cfg.host}`)"
          "--label=traefik.http.routers.soketi-http.entrypoints=web"
          "--label=traefik.http.routers.soketi-http.middlewares=soketi-https-redirect"
          "--label=traefik.http.routers.soketi.rule=Host(`${cfg.host}`)"
          "--label=traefik.http.routers.soketi.entrypoints=websecure"
          "--label=traefik.http.routers.soketi.tls=true"
          "--label=traefik.http.services.soketi.loadbalancer.server.port=6001"
        ];
        environment = {
          SOKETI_DEBUG = "1";
          SOKETI_METRICS_SERVER_PORT = "9601";
          SOKETI_DEFAULT_APP_ID = "soketi";
          SOKETI_DEFAULT_APP_KEY = "soketi";
          SOKETI_DEFAULT_APP_SECRET = "soketi";
        };
        log-driver = config.modules.containers.settings.log-driver;
      };
    };
  };
}
