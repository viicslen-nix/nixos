{
  flake.modules.nixos.macos-vm = {
    lib,
    pkgs,
    config,
    ...
  }:
    with lib; let
      name = "macos-vm";
      namespace = "features";

      cfg = config.modules.${namespace}.${name};
      engine = config.virtualisation.oci-containers.backend;
      nvidia = config.hardware.nvidia-container-toolkit.enable;

      # TODO: pull docker.io/dockurr/macos instead once a release ships Reims vGPU (v3.12 does not).
      rev = "16a5b470cdd601bae8b05b02d748d7edfb36c12e";
      image = "localhost/dockurr-macos:${substring 0 12 rev}";

      launcher = pkgs.writeShellApplication {
        name = "macos-vm";
        runtimeInputs = [pkgs.quickemu pkgs.gnused];
        text = ''
          dir="''${XDG_DATA_HOME:-$HOME/.local/share}/macos-vm"
          mkdir -p "$dir"
          cd "$dir"
          conf="macos-${cfg.release}.conf"
          [ -e "$conf" ] || quickget macos ${cfg.release}
          sed -i '/^\(cpu_cores\|ram\)=/d' "$conf"
          printf 'cpu_cores="%s"\nram="%s"\n' ${toString cfg.cores} ${cfg.memory} >> "$conf"
          exec quickemu --vm "$conf" "$@"
        '';
      };
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        backend = mkOption {
          type = types.enum ["container" "quickemu"];
          default = "container";
          description = ''
            `container` runs dockur/macos on `virtualisation.oci-containers.backend`
            (web viewer on http://localhost:8006, VNC on :5900; start it with
            `systemctl start ${engine}-macos-vm`). `quickemu` installs a
            `macos-vm` launcher that opens a local window.
          '';
        };

        release = mkOption {
          type = types.enum ["catalina" "big-sur" "monterey" "ventura" "sonoma" "sequoia" "tahoe"];
          default = "sequoia";
          description = "macOS release, by the codename both dockur and quickget accept.";
        };

        cores = mkOption {
          type = types.ints.positive;
          default = 4;
        };

        memory = mkOption {
          type = types.str;
          default = "8G";
        };

        gpu = mkEnableOption (mdDoc ''
          Reims vGPU acceleration (container backend only, experimental). Upstream
          has only tested x86 guests on `tahoe`, and the guest needs Metal's error
          mode set once from Recovery before its desktop comes up
        '');
      };

      config = mkIf cfg.enable (mkMerge [
        {
          boot.extraModprobeConfig = "options kvm ignore_msrs=1 report_ignored_msrs=0";

          assertions = [
            {
              assertion = cfg.gpu -> cfg.backend == "container";
              message = "modules.features.macos-vm.gpu needs backend = \"container\"; quickemu has no Reims vGPU.";
            }
          ];
        }

        (mkIf (cfg.backend == "quickemu") {
          environment.systemPackages = [launcher];
        })

        (mkIf (cfg.backend == "container") {
          systemd.services.macos-vm-image = {
            description = "Build the dockur/macos image";
            requiredBy = ["${engine}-macos-vm.service"];
            before = ["${engine}-macos-vm.service"];
            wants = ["network-online.target"];
            after = ["network-online.target"] ++ optional (engine == "docker") "docker.service";
            path = [config.virtualisation.${engine}.package pkgs.git];
            serviceConfig.Type = "oneshot";
            script = ''
              ${engine} image inspect ${image} >/dev/null 2>&1 \
                || ${engine} build -t ${image} "https://github.com/dockur/macos.git#${rev}"
            '';
          };

          virtualisation.oci-containers.containers.macos-vm = {
            inherit image;
            autoStart = false;
            pull = "never";
            ports = ["127.0.0.1:8006:8006" "127.0.0.1:5900:5900"];
            volumes =
              ["macos-vm:/storage:idmap"]
              ++ optionals (cfg.gpu && nvidia) [
                # The driver's Vulkan ICD and its RUNPATH deps live in the store, not in the Debian image.
                "/nix/store:/nix/store:ro"
                "${config.hardware.nvidia.package}/share/vulkan/icd.d/nvidia_icd.json:/etc/vulkan/icd.d/nvidia_icd.json:ro"
              ];
            environment =
              {
                VERSION = cfg.release;
                CPU_CORES = toString cfg.cores;
                RAM_SIZE = cfg.memory;
              }
              // optionalAttrs cfg.gpu {GPU = "Y";}
              // optionalAttrs (cfg.gpu && nvidia) {NVIDIA_DRIVER_CAPABILITIES = "all";};
            devices =
              ["/dev/kvm" "/dev/net/tun"]
              ++ optionals cfg.gpu (["/dev/dri" "/dev/udmabuf"] ++ optional nvidia "nvidia.com/gpu=all");
            capabilities.NET_ADMIN = true;
            extraOptions =
              # Lets macOS shut down cleanly; must stay below the unit's TimeoutStopSec (120).
              ["--stop-timeout=110"]
              # A mapped root cannot open /dev/udmabuf (root:kvm 0660).
              ++ optional cfg.gpu "--userns=host";
          };
        })
      ]);
    };
}
