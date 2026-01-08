{
  lib,
  config,
  ...
}:
with lib; let
  name = "centrifugo";
  namespace = "containers";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    host = mkOption {
      type = types.str;
      default = "centrifugo.local";
      description = "Hostname for Centrifugo";
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
      centrifugo = {
        hostname = "centrifugo";
        image = "centrifugo/centrifugo:latest";
        ports = [
          "127.0.0.1:8000:8000"
        ];
        extraOptions = [
          "--network=local"
          "--label=traefik.enable=true"
          "--label=traefik.http.middlewares.centrifugo-https-redirect.redirectscheme.scheme=https"
          "--label=traefik.http.middlewares.centrifugo-https-redirect.redirectscheme.permanent=true"
          "--label=traefik.http.routers.centrifugo-http.rule=Host(`${cfg.host}`)"
          "--label=traefik.http.routers.centrifugo-http.entrypoints=web"
          "--label=traefik.http.routers.centrifugo-http.middlewares=centrifugo-https-redirect"
          "--label=traefik.http.routers.centrifugo.rule=Host(`${cfg.host}`)"
          "--label=traefik.http.routers.centrifugo.entrypoints=websecure"
          "--label=traefik.http.routers.centrifugo.tls=true"
          "--label=traefik.http.services.centrifugo.loadbalancer.server.port=8000"
        ];
        volumes = [
          "centrifugo-config:/centrifugo"
        ];
        environment = {
          CENTRIFUGO_ADMIN = "true";
          CENTRIFUGO_ADMIN_PASSWORD = "admin";
          CENTRIFUGO_ADMIN_SECRET = "change-this-secret";
          CENTRIFUGO_TOKEN_HMAC_SECRET_KEY = "change-this-token-secret";
          CENTRIFUGO_API_KEY = "change-this-api-key";
        };
        cmd = ["centrifugo" "--config=/centrifugo/config.json"];
        log-driver = config.modules.containers.settings.log-driver;
      };
    };
  };
}
