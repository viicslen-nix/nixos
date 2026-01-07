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

    host = mkOption {
      type = types.str;
      default = "postgres.local";
      description = "Hostname for PostgreSQL";
    };
  };

  config = mkIf cfg.enable {
    networking.hosts."127.0.0.1" = [cfg.host];

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
        volumes = [
          "pgdata:/var/lib/postgresql/data"
        ];
        environment = {
          POSTGRES_PASSWORD = "secret";
        };
        log-driver = config.modules.containers.settings.log-driver;
      };
    };
  };
}
