{
  flake.modules.nixos.mysql = {
    inputs,
    lib,
    config,
    ...
  }:
    with lib; let
      inherit (inputs.self.lib.containers) mkHostOption mkMkcertDomains mkTraefikLabels;

      name = "mysql";
      namespace = "containers";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        host = mkHostOption "mysql.local" "MySQL";
      };

      config = mkIf cfg.enable {
        networking.hosts."127.0.0.1" = [cfg.host];

        modules.programs.mkcert = mkMkcertDomains config [cfg.host];

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
              "--max-connections=1000"
            ];
            environment = {
              MYSQL_ROOT_PASSWORD = "secret";
            };
            log-driver = config.modules.containers.settings.log-driver;
          };
        };
      };
    };
}
