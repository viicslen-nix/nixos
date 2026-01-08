{
  lib,
  config,
  ...
}:
with lib; let
  name = "homarr";
  namespace = "containers";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    host = mkOption {
      type = types.str;
      default = "home.local";
      description = "Hostname for Homarr";
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
      homarr = {
        hostname = "homarr";
        image = "ghcr.io/ajnart/homarr:latest";
        ports = [
          "127.0.0.1:7575:7575"
        ];
        volumes = [
          "homarr-configs:/app/data/configs"
          "homarr-data:/data"
          "homarr-icons:/app/public/icons"
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
        extraOptions = [
          "--network=local"
          "--label=traefik.enable=true"
          "--label=traefik.http.middlewares.homarr-https-redirect.redirectscheme.scheme=https"
          "--label=traefik.http.middlewares.homarr-https-redirect.redirectscheme.permanent=true"
          "--label=traefik.http.routers.homarr-http.rule=Host(`${cfg.host}`)"
          "--label=traefik.http.routers.homarr-http.entrypoints=web"
          "--label=traefik.http.routers.homarr-http.middlewares=homarr-https-redirect"
          "--label=traefik.http.routers.homarr.rule=Host(`${cfg.host}`)"
          "--label=traefik.http.routers.homarr.entrypoints=websecure"
          "--label=traefik.http.routers.homarr.tls=true"
          "--label=traefik.http.services.homarr.loadbalancer.server.port=7575"
        ];
        log-driver = config.modules.containers.settings.log-driver;
      };
    };
  };
}
