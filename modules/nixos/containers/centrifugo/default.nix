{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "centrifugo";
  namespace = "containers";

  cfg = config.modules.${namespace}.${name};

  centrifugoConfig = pkgs.writeText "centrifugo-config.json" (builtins.toJSON {
    log.level = "trace";
    debug.enabled = true;
    http_api.key = "api-key";
    admin = {
      enabled = true;
      password = "secret";
      secret = "secret";
    };
    client = {
      token.hmac_secret_key = "secret-key";
      allowed_origins = ["*"];
    };
    channel = {
      without_namespace = {
        presence = true;
        join_leave = true;
        allow_subscribe_for_client = true;
        allow_history_for_subscriber = true;
        allow_presence_for_subscriber = true;
      };
      namespaces = [
        {
          name = "private";
          presence = true;
          join_leave = true;
          allow_history_for_subscriber = true;
          allow_presence_for_subscriber = true;
        }
      ];
    };
  });
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
          "127.0.0.1:8002:8000"
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
          "${centrifugoConfig}:/centrifugo/config.json:ro"
        ];
        cmd = ["centrifugo" "--config=/centrifugo/config.json"];
        log-driver = config.modules.containers.settings.log-driver;
      };
    };
  };
}
