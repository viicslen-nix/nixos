{
  flake.modules.nixos.centrifugo = {
    inputs,
    lib,
    pkgs,
    config,
    ...
  }:
    with lib; let
      inherit (inputs.self.lib.containers) mkHostOption mkMkcertDomains mkTraefikLabels;

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
        enable = mkEnabledOption (mdDoc name);

        host = mkHostOption "centrifugo.local" "Centrifugo";
      };

      config = mkIf cfg.enable {
        networking.hosts."127.0.0.1" = [cfg.host];

        modules.programs.mkcert = mkMkcertDomains config [cfg.host];

        virtualisation.oci-containers.containers = {
          centrifugo = {
            hostname = "centrifugo";
            image = "centrifugo/centrifugo:latest";
            ports = [
              "127.0.0.1:8002:8000"
            ];
            extraOptions =
              [
                "--network=local"
              ]
              ++ mkTraefikLabels {
                name = "centrifugo";
                host = cfg.host;
                port = 8000;
              };
            volumes = [
              "${centrifugoConfig}:/centrifugo/config.json:ro"
            ];
            cmd = ["centrifugo" "--config=/centrifugo/config.json"];
            log-driver = config.modules.containers.settings.log-driver;
          };
        };
      };
    };
}
