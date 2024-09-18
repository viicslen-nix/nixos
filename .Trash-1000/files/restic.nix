{
  user,
  lib,
  config,
  ...
}: {
  age.identityPaths = [ "${config.users.users.${user}.home}/.ssh/agenix" ];

  # configure agenix secrets
  age.secrets = {
    "restic/env".file = ./secrets/restic/env.age;
    "restic/repo".file = ./secrets/restic/repo.age;
    "restic/password".file = ./secrets/restic/password.age;
  };

  # configure restic backup services
  services.restic.backups = {
    daily = {
      initialize = true;

      environmentFile = config.age.secrets."restic/env".path;
      repositoryFile = config.age.secrets."restic/repo".path;
      passwordFile = config.age.secrets."restic/password".path;

      paths = (lib.lists.forEach [
        "Development"
        "Documents"
      ] (dir: "${config.users.users.${user}.home}/${dir}"));

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
    };
  };
}