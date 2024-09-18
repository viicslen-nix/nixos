{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "backups";
  namespace = "features";

  cfg = config.${namespace}.${name};

  userDirs = concatLists (lists.forEach cfg.home.users (user: lists.forEach cfg.home.paths (dir: "${config.users.users.${user}.home}/${dir}")));
in {
  options.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
    
    repository = mkOption {
      type = types.str;
      description = ''
        The path to the restic repository.
      '';
    };

    secrets = {
      env = mkOption {
        type = types.path;
        description = ''
          The path to the age encrypted environment file.
        '';
      };
      password = mkOption {
        type = types.path;
        description = ''
          The path to the age encrypted password file.
        '';
      };
    };

    paths = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        List of paths to backup.
      '';
    };

    exclude = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Patterns to exclude when backing up paths.
      '';
    };

    home = {
      users = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          The user to configure backups for for.
        '';
      };

      paths = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          List of paths to backup.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # configure agenix secrets
    age.secrets = {
      "restic/env".file = cfg.secrets.env;
      "restic/password".file = cfg.secrets.password;
    };

    # configure restic backup services
    services.restic.backups = {
      daily = {
        initialize = true;

        environmentFile = config.age.secrets."restic/env".path;
        passwordFile = config.age.secrets."restic/password".path;

        repository = cfg.repository;

        paths = concatLists [
          cfg.paths
          userDirs
        ];

        exclude = cfg.exclude;

        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
        ];
      };
    };
  };
}
