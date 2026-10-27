{
  flake.modules.nixos.actions-runner = {
    lib,
    config,
    ...
  }:
    with lib; let
      name = "actions-runner";
      namespace = "containers";

      cfg = config.modules.${namespace}.${name};
      dataDir = "/var/lib/actions-runner";
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
        systemd.tmpfiles.rules = [
          "d ${dataDir} 0700 root root -"
          "d ${dataDir}/config 0700 root root -"
          "d ${dataDir}/work 0755 root root -"
        ];

        virtualisation.oci-containers.containers.actions-runner = {
          image = "myoung34/github-runner:ubuntu-noble";
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
