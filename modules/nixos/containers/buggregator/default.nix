{
  lib,
  config,
  ...
}:
with lib; let
  name = "buggregator";
  namespace = "containers";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    host = mkOption {
      type = types.str;
      default = "buggregator.local";
      description = "Hostname for Buggregator";
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
      buggregator = {
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
          "--label=traefik.enable=true"
          "--label=traefik.http.middlewares.buggregator-https-redirect.redirectscheme.scheme=https"
          "--label=traefik.http.middlewares.buggregator-https-redirect.redirectscheme.permanent=true"
          "--label=traefik.http.routers.buggregator-http.rule=Host(`${cfg.host}`)"
          "--label=traefik.http.routers.buggregator-http.entrypoints=web"
          "--label=traefik.http.routers.buggregator-http.middlewares=buggregator-https-redirect"
          "--label=traefik.http.routers.buggregator.rule=Host(`${cfg.host}`)"
          "--label=traefik.http.routers.buggregator.entrypoints=websecure"
          "--label=traefik.http.routers.buggregator.tls=true"
          "--label=traefik.http.services.buggregator.loadbalancer.server.port=8000"
        ];
        volumes = [
          "${builtins.toString ./config}:/app/runtime/configs"
        ];
        log-driver = config.modules.containers.settings.log-driver;
      };
    };
  };
}
