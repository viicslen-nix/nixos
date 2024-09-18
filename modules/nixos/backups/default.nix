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

  jobName = "daily";
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

    notifications = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable notifications on backup failure.
      '';
    };

    exclude = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Patterns to exclude when backing up paths.
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
    # configure agenix secrets
    age.secrets = {
      "restic/env".file = cfg.secrets.env;
      "restic/password".file = cfg.secrets.password;
    };

    # configure restic backup services
    services.restic.backups = {
      ${jobName} = {
        initialize = true;
        repository = cfg.repository;

        environmentFile = config.age.secrets."restic/env".path;
        passwordFile = config.age.secrets."restic/password".path;

        timeConfig = {
          OnCalendar = "16:00";
          Persistent = true;
        };

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

    environment.systemPackages = [ pkgs.libnotify ];

    systemd.services = mkIf cfg.notifications {
      "restic-backups-${jobName}".unitConfig.OnFailure = "notify-backup-failed.service";

      "notify-backup-failed" = {
        enable = true;
        description = "Notify on failed backup";
        serviceConfig = {
          Type = "oneshot";
          User = config.users.users.arthur.name;
        };

        # required for notify-send
        environment.DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${toString config.users.users.arthur.uid}/bus";

        script = ''
          ${pkgs.libnotify}/bin/notify-send --urgency=critical \
            "Backup failed" \
            "$(journalctl -u restic-backups-daily -n 5 -o cat)"
        '';
      };
    };
  };
}
