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
    privateKeyPath = mkOption {
      type = types.str;
      description = ''
        The path to the private key to use for encryption.
      '';
    };
    repository = mkOption {
      type = types.str;
      description = ''
        The path to the restic repository.
      '';
    };
    paths = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        List of paths to backup.
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
    age.identityPaths = [ privateKeyPath ];

    # configure agenix secrets
    age.secrets = {
      "restic/env".file = ./secrets/env.age;
      "restic/password".file = ./secrets/password.age;
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

        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
        ];
      };
    };
  };
}
