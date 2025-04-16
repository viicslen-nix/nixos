{
  lib,
  config,
  ...
}:
with lib; let
  name = "postgres";
  namespace = "containers";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      postgres = {
        hostname = "postgres";
        image = "postgres:latest";
        ports = [
          "127.0.0.1:5432:5432"
        ];
        extraOptions = [
          "--network=local"
        ];
        environment = {
          POSTGRES_PASSWORD = "secret";
        };
        log-driver = config.modules.containers.settings.log-driver;
      };
    };
  };
}
