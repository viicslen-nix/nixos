{
  flake.modules.nixos.actions-runner = {
    lib,
    pkgs,
    config,
    ...
  }:
    with lib; let
      name = "actions-runner";
      namespace = "containers";

      cfg = config.modules.${namespace}.${name};
      dataDir = "/var/lib/actions-runner";

      image = "localhost/actions-runner:mlh";
      # Jobs call these from the runner container itself, unlike the hosted runners that ship them.
      containerfile = pkgs.writeTextDir "Containerfile" ''
        FROM docker.io/myoung34/github-runner:ubuntu-noble
        RUN apt-get update \
          && apt-get install -y --no-install-recommends mariadb-client libvips42t64 sudo \
          && rm -rf /var/lib/apt/lists/*
      '';
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        org = mkOption {
          type = types.str;
          example = "FmTod";
          description = "GitHub organization the runner registers against.";
        };

        labels = mkOption {
          type = types.str;
          default = "mlh-local";
          description = "Comma-separated runner labels.";
        };
      };

      config = mkIf cfg.enable {
        systemd = {
          tmpfiles.rules = [
            "d ${dataDir} 0700 root root -"
            "d ${dataDir}/config 0700 root root -"
            "d ${dataDir}/work 0755 root root -"
          ];

          services.actions-runner-image = {
            description = "Build the actions-runner image";
            before = ["podman-actions-runner.service"];
            requiredBy = ["podman-actions-runner.service"];
            path = [config.virtualisation.podman.package];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = "podman build --pull=newer -t ${image} ${containerfile}";
          };

          services.podman-actions-runner.restartTriggers = [containerfile];
        };

        virtualisation.oci-containers.containers.actions-runner = {
          inherit image;
          environment = {
            ORG_NAME = cfg.org;
            RUNNER_SCOPE = "org";
            RUNNER_NAME = config.networking.hostName;
            LABELS = cfg.labels;
            CONFIGURED_ACTIONS_RUNNER_FILES_DIR = "/runner/config";
            DISABLE_AUTOMATIC_DEREGISTRATION = "true";
            # Must match the host path: service and action containers are siblings on the host engine.
            RUNNER_WORKDIR = "${dataDir}/work";
          };
          # RUNNER_TOKEN=<registration token>; only read on first registration.
          environmentFiles = ["${dataDir}/token.env"];
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock"
            "${dataDir}/config:/runner/config"
            "${dataDir}/work:${dataDir}/work"
          ];
          extraOptions = [
            # Job services publish on the host; steps reach them via 127.0.0.1.
            "--network=host"
            "--memory=12g"
            "--cpus=16"
          ];
          log-driver = config.modules.containers.settings.log-driver;
        };
      };
    };
}
