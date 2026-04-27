{
  lib,
  config,
  ...
}:
with lib; let
  name = "vitess";
  namespace = "containers";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    host = mkOption {
      type = types.str;
      default = "vitess.local";
      description = "Hostname for Vitess";
    };

    port = mkOption {
      type = types.port;
      default = 33574;
      description = "Base port for Vitess components (vtcombo debug/status dashboard)";
    };

    keyspaces = mkOption {
      type = types.str;
      default = "test";
      example = "test,unsharded";
      description = "Comma-separated list of keyspace names to create";
    };

    numShards = mkOption {
      type = types.str;
      default = "1";
      example = "2,1";
      description = "Comma-separated number of shards per keyspace (read in conjunction with keyspaces)";
    };

    mysqlMaxConnections = mkOption {
      type = types.int;
      default = 1000;
      description = "Maximum number of connections that the MySQL instance will support";
    };

    mysqlBindHost = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Which host to bind the MySQL listener to";
    };

    vtcomboBindHost = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Which host to bind the vtcombo servenv listener to";
    };

    charset = mkOption {
      type = types.str;
      default = "utf8mb4";
      description = "Default charset to use";
    };

    persistData = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to persist MySQL data and VSchema objects across restarts";
    };
  };

  config = mkIf cfg.enable {
    networking.hosts."127.0.0.1" = [cfg.host];

    virtualisation.oci-containers.containers = {
      vitess = {
        hostname = "vitess";
        image = "vitess/vttestserver:mysql84";
        ports = let
          p = toString cfg.port;
          vtctld = toString (cfg.port + 1);
          vtgate = toString (cfg.port + 3);
        in [
          "127.0.0.1:${p}:${p}"
          "127.0.0.1:${vtctld}:${vtctld}"
          "127.0.0.1:${vtgate}:${vtgate}"
        ];
        volumes = optionals cfg.persistData [
          "vttestserver-data:/vt/vtdataroot"
        ];
        environment = {
          PORT = toString cfg.port;
          KEYSPACES = cfg.keyspaces;
          NUM_SHARDS = cfg.numShards;
          MYSQL_MAX_CONNECTIONS = toString cfg.mysqlMaxConnections;
          MYSQL_BIND_HOST = cfg.mysqlBindHost;
          VTCOMBO_BIND_HOST = cfg.vtcomboBindHost;
          CHARSET = cfg.charset;
        };
        cmd = optionals cfg.persistData [
          "/vt/bin/vttestserver"
          "--alsologtostderr"
          "--data-dir=/vt/vtdataroot/"
          "--persistent-mode"
          "--port=${toString cfg.port}"
          "--mysql-bind-host=${cfg.mysqlBindHost}"
          "--vtcombo-bind-host=${cfg.vtcomboBindHost}"
          "--keyspaces=${cfg.keyspaces}"
          "--num-shards=${cfg.numShards}"
        ];
        extraOptions = [
          "--health-cmd=mysqladmin ping -h127.0.0.1 -P${toString (cfg.port + 3)}"
          "--health-interval=5s"
          "--health-timeout=2s"
          "--health-retries=5"
        ];
        networks = [
          "local"
        ];
        log-driver = config.modules.containers.settings.log-driver;
      };
    };
  };
}
