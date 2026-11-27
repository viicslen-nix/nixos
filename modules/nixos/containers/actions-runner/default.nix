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

      # Runner 1 keeps the unsuffixed names so its existing registration survives.
      suffix = i: optionalString (i > 1) "-${toString i}";
      runners = genList (i: let
        n = i + 1;
      in {
        name = "${name}${suffix n}";
        runnerName = "${config.networking.hostName}${suffix n}";
        dataDir = "/var/lib/${name}${suffix n}";
      }) cfg.count;

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

        count = mkOption {
          type = types.ints.positive;
          default = 1;
          description = "Number of runners registered from this host, each running one job at a time.";
        };
      };

      config = mkIf cfg.enable {
        systemd = {
          tmpfiles.rules = concatMap (r: [
            "d ${r.dataDir} 0700 root root -"
            "d ${r.dataDir}/config 0700 root root -"
            "d ${r.dataDir}/work 0755 root root -"
          ])
          runners;

          services =
            {
              actions-runner-image = {
                description = "Build the actions-runner image";
                before = map (r: "podman-${r.name}.service") runners;
                requiredBy = map (r: "podman-${r.name}.service") runners;
                path = [config.virtualisation.podman.package];
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                };
                script = "podman build --pull=newer -t ${image} ${containerfile}";
              };
            }
            // listToAttrs (map (r: nameValuePair "podman-${r.name}" {restartTriggers = [containerfile];}) runners);
        };

        virtualisation.oci-containers.containers = listToAttrs (map (r:
          nameValuePair r.name {
            inherit image;
            environment = {
              ORG_NAME = cfg.org;
              RUNNER_SCOPE = "org";
              RUNNER_NAME = r.runnerName;
              LABELS = cfg.labels;
              CONFIGURED_ACTIONS_RUNNER_FILES_DIR = "/runner/config";
              DISABLE_AUTOMATIC_DEREGISTRATION = "true";
              # Must match the host path: service and action containers are siblings on the host engine.
              RUNNER_WORKDIR = "${r.dataDir}/work";
            };
            # RUNNER_TOKEN=<registration token>; only read on first registration.
            environmentFiles = ["${r.dataDir}/token.env"];
            volumes = [
              "/run/podman/podman.sock:/var/run/docker.sock"
              "${r.dataDir}/config:/runner/config"
              "${r.dataDir}/work:${r.dataDir}/work"
            ];
            extraOptions = [
              # Job services publish on the host; steps reach them via 127.0.0.1.
              "--network=host"
              "--memory=12g"
              "--cpus=16"
            ];
            log-driver = config.modules.containers.settings.log-driver;
          })
        runners);
      };
    };
}
