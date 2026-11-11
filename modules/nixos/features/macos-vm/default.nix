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
      unitOf = n: "${engine}-macos-${n}.service";
      names = concatStringsSep "|" (attrNames cfg.instances);

      # TODO: pull docker.io/dockurr/macos instead once a release ships Reims vGPU (v3.12 does not).
      rev = "16a5b470cdd601bae8b05b02d748d7edfb36c12e";
      image = "localhost/dockurr-macos:${substring 0 12 rev}";
      src = pkgs.fetchFromGitHub {
        owner = "dockur";
        repo = "macos";
        inherit rev;
        hash = "sha256-NMu6THxpiEpl2PpR+/8ZFYZNKNbwJu6wseieBJs5LQA=";
      };

      usage = ''
        *) echo "usage: macos-vm <${names}>${optionalString (cfg.backend == "container") " [type TEXT]"}" >&2; exit 2 ;;
      '';

      quickemuLauncher = pkgs.writeShellApplication {
        name = "macos-vm";
        runtimeInputs = [pkgs.quickemu pkgs.gnused];
        text = ''
          name=''${1-}
          case "$name" in
            ${concatStrings (mapAttrsToList (n: i: ''
              ${n}) release=${i.release} cores=${toString i.cores} memory=${i.memory} ;;
            '')
            cfg.instances)}
            ${usage}
          esac
          dir="''${XDG_DATA_HOME:-$HOME/.local/share}/macos-vm/$name"
          mkdir -p "$dir"
          cd "$dir"
          conf="macos-$release.conf"
          [ -e "$conf" ] || quickget macos "$release"
          sed -i '/^\(cpu_cores\|ram\)=/d' "$conf"
          printf 'cpu_cores="%s"\nram="%s"\n' "$cores" "$memory" >> "$conf"
          exec quickemu --vm "$conf"
        '';
      };

      containerLauncher = pkgs.writeShellApplication {
        name = "macos-vm";
        runtimeInputs = [pkgs.systemd pkgs.virt-viewer pkgs.libnotify config.virtualisation.${engine}.package];
        text = ''
          name=''${1-}
          case "$name" in
            ${concatStrings (mapAttrsToList (n: i: ''
              ${n}) unit=${unitOf n} vnc=${toString (5900 + i.display)} ;;
            '')
            cfg.instances)}
            ${usage}
          esac

          if [ "''${2-}" = type ]; then
            text=''${3-$(cat)}
            # The CLI user is not root, so reach the rootful engine through its socket.
            exec ${
            if engine == "podman"
            then "podman --url unix:///run/podman/podman.sock"
            else "docker"
          } exec -i "macos-$name" python3 - "$text" < ${./sendkeys.py}
          fi

          vnc_up() { (exec 3<>"/dev/tcp/127.0.0.1/$vnc") 2>/dev/null; }

          if ! systemctl -q is-active "$unit"; then
            notify-send "macOS $name" "Starting the VM. The first run downloads and installs macOS." || true
            systemctl start "$unit"
          fi
          until vnc_up; do
            if ! systemctl -q is-active "$unit"; then
              notify-send -u critical "macOS $name" "The VM stopped: journalctl -u $unit" || true
              exit 1
            fi
            sleep 2
          done
          exec remote-viewer --title "macOS $name" "vnc://127.0.0.1:$vnc"
        '';
      };

      desktopItem = n: _:
        pkgs.makeDesktopItem {
          name = "macos-${n}";
          desktopName = "macOS ${n}";
          comment = "macOS virtual machine";
          exec = "macos-vm ${n}";
          icon = "computer";
          categories = ["System" "Emulator"];
          actions = optionalAttrs (cfg.backend == "container") {
            stop = {
              name = "Shut down";
              exec = "systemctl stop ${unitOf n}";
            };
          };
        };

      instanceModule = {
        options = {
          release = mkOption {
            type = types.enum ["catalina" "big-sur" "monterey" "ventura" "sonoma" "sequoia" "tahoe"];
            description = "macOS release, by the codename both dockur and quickget accept.";
          };

          display = mkOption {
            type = types.ints.between 0 99;
            description = "Unique per instance: VNC listens on 5900 + display, the web viewer on 8006 + display.";
          };

          cores = mkOption {
            type = types.ints.positive;
            default = 4;
          };

          memory = mkOption {
            type = types.str;
            default = "8G";
          };

          picker = mkEnableOption (mdDoc ''
            OpenCore's boot picker with Recovery listed, waiting 60s (container
            backend). Needed once with `gpu` to set Metal's error mode from Recovery
          '');

          gpu = mkEnableOption (mdDoc ''
            Reims vGPU acceleration (container backend only, experimental). Upstream
            has only tested x86 guests on `tahoe`, and the guest needs Metal's error
            mode set once before its desktop comes up
          '');
        };
      };

      container = n: i: {
        inherit image;
        autoStart = false;
        pull = "never";
        ports = [
          "127.0.0.1:${toString (8006 + i.display)}:8006"
          "127.0.0.1:${toString (5900 + i.display)}:5900"
        ];
        volumes =
          ["macos-${n}:/storage:idmap"]
          ++ optionals (i.gpu && nvidia) [
            # The driver's Vulkan ICD and its RUNPATH deps live in the store, not in the Debian image.
            "/nix/store:/nix/store:ro"
            "${config.hardware.nvidia.package}/share/vulkan/icd.d/nvidia_icd.json:/etc/vulkan/icd.d/nvidia_icd.json:ro"
          ];
        environment =
          {
            VERSION = i.release;
            CPU_CORES = toString i.cores;
            RAM_SIZE = i.memory;
          }
          // optionalAttrs i.picker {PICKER = "Y";}
          // optionalAttrs i.gpu {GPU = "Y";}
          // optionalAttrs (i.gpu && nvidia) {NVIDIA_DRIVER_CAPABILITIES = "all";};
        devices =
          ["/dev/kvm" "/dev/net/tun"]
          ++ optionals i.gpu (["/dev/dri" "/dev/udmabuf"] ++ optional nvidia "nvidia.com/gpu=all");
        capabilities.NET_ADMIN = true;
        extraOptions =
          # Lets macOS shut down cleanly; must stay below the unit's TimeoutStopSec (120).
          ["--stop-timeout=110"]
          # A mapped root cannot open /dev/udmabuf (root:kvm 0660).
          ++ optional i.gpu "--userns=host";
      };
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        backend = mkOption {
          type = types.enum ["container" "quickemu"];
          default = "container";
          description = ''
            `container` runs dockur/macos on `virtualisation.oci-containers.backend`;
            `macos-vm <instance>` starts it and opens remote-viewer, and
            http://localhost:<8006 + display> also works. `quickemu` makes
            `macos-vm <instance>` open a local quickemu window.
          '';
        };

        instances = mkOption {
          type = types.attrsOf (types.submodule instanceModule);
          default = {};
          example = literalExpression ''{ sequoia = { release = "sequoia"; display = 0; }; }'';
          description = "macOS VMs, each with its own disk (`macos-<name>` volume), unit and desktop entry.";
        };
      };

      config = mkIf (cfg.enable && cfg.instances != {}) (mkMerge [
        {
          boot.extraModprobeConfig = "options kvm ignore_msrs=1 report_ignored_msrs=0";

          environment.systemPackages =
            [
              (
                if cfg.backend == "container"
                then containerLauncher
                else quickemuLauncher
              )
            ]
            ++ mapAttrsToList desktopItem cfg.instances;

          assertions = let
            displays = mapAttrsToList (_: i: i.display) cfg.instances;
          in [
            {
              assertion = cfg.backend == "container" || all (i: !i.gpu && !i.picker) (attrValues cfg.instances);
              message = "modules.features.macos-vm: gpu and picker need backend = \"container\".";
            }
            {
              assertion = length displays == length (unique displays);
              message = "modules.features.macos-vm: each instance needs its own display number.";
            }
          ];
        }

        (mkIf (cfg.backend == "container") {
          # Lets the launcher start/stop the VMs without a password prompt.
          security.polkit.extraConfig = ''
            polkit.addRule(function (action, subject) {
              var units = ${builtins.toJSON (map unitOf (attrNames cfg.instances))};
              if (action.id == "org.freedesktop.systemd1.manage-units" &&
                  units.indexOf(action.lookup("unit")) >= 0 && subject.isInGroup("wheel")) {
                return polkit.Result.YES;
              }
            });
          '';

          systemd.services.macos-vm-image = let
            units = map unitOf (attrNames cfg.instances);
          in {
            description = "Build the dockur/macos image";
            requiredBy = units;
            before = units;
            wants = ["network-online.target"];
            after = ["network-online.target"] ++ optional (engine == "docker") "docker.service";
            path = [config.virtualisation.${engine}.package];
            serviceConfig.Type = "oneshot";
            script = ''
              ${engine} image inspect ${image} >/dev/null 2>&1 || ${engine} build -t ${image} ${src}
            '';
          };

          virtualisation.oci-containers.containers = mapAttrs' (n: i: nameValuePair "macos-${n}" (container n i)) cfg.instances;
        })
      ]);
    };
}
