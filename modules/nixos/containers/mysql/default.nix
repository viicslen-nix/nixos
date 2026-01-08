{
  lib,
  config,
  ...
}:
with lib; let
  name = "mysql";
  namespace = "containers";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    host = mkOption {
      type = types.str;
      default = "mysql.local";
      description = "Hostname for MySQL";
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
      mysql = {
        hostname = "mysql";
        image = "percona/percona-server:latest";
        ports = [
          "127.0.0.1:3306:3306"
        ];
        volumes = [
          "percona-mysql:/var/lib/mysql"
          "percona-mysql-config:/etc/my.cnf.d"
        ];
        networks = [
          "local"
        ];
        cmd = [
          "--disable-log-bin"
        ];
        environment = {
          MYSQL_ROOT_PASSWORD = "secret";
        };
        log-driver = config.modules.containers.settings.log-driver;
      };
    };
  };
}
