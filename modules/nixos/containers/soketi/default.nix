{
  flake.modules.nixos.soketi = {
    inputs,
    lib,
    config,
    ...
  }:
    with lib; let
      inherit (inputs.self.lib.containers) mkHostOption mkMkcertDomains mkTraefikLabels;

      name = "soketi";
      namespace = "containers";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        host = mkHostOption "soketi.local" "Soketi";
      };

      config = mkIf cfg.enable {
        networking.hosts."127.0.0.1" = [cfg.host];

        modules.programs.mkcert = mkMkcertDomains config [cfg.host];

        virtualisation.oci-containers.containers = {
          soketi = {
            hostname = "soketi";
            image = "quay.io/soketi/soketi:latest-16-alpine";
            ports = [
              "127.0.0.1:6001:6001"
              "127.0.0.1:9601:9601"
            ];
            extraOptions =
              [
                "--network=local"
              ]
              ++ mkTraefikLabels {
                name = "soketi";
                host = cfg.host;
                port = 6001;
              };
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
    };
}
