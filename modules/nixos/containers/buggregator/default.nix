{
  flake.modules.nixos.buggregator = {
    inputs,
    lib,
    config,
    ...
  }:
    with lib; let
      inherit (inputs.self.lib.containers) mkHostOption mkMkcertDomains mkTraefikLabels;

      name = "buggregator";
      namespace = "containers";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        host = mkHostOption "buggregator.local" "Buggregator";
      };

      config = mkIf cfg.enable {
        networking.hosts."127.0.0.1" = [cfg.host];

        modules.programs.mkcert = mkMkcertDomains config [cfg.host];

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
            extraOptions =
              [
                "--network=local"
              ]
              ++ mkTraefikLabels {
                name = "buggregator";
                host = cfg.host;
                port = 8000;
              };
            volumes = [
              "${builtins.toString ./config}:/app/runtime/configs"
            ];
            log-driver = config.modules.containers.settings.log-driver;
          };
        };
      };
    };
}
