{
  flake.modules.nixos.redis = {
    inputs,
    lib,
    config,
    ...
  }:
    with lib; let
      inherit (inputs.self.lib.containers) mkHostOption mkMkcertDomains mkTraefikLabels;

      name = "redis";
      namespace = "containers";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        host = mkHostOption "redis.local" "Redis";
      };

      config = mkIf cfg.enable {
        networking.hosts."127.0.0.1" = [cfg.host];

        modules.programs.mkcert = mkMkcertDomains config [cfg.host];

        virtualisation.oci-containers.containers = {
          redis = {
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
            log-driver = config.modules.containers.settings.log-driver;
          };
        };
      };
    };
}
