{
  flake.modules.nixos.oom = {
    lib,
    config,
    ...
  }:
    with lib; let
      name = "oom";
      namespace = "services";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc feature);

        prefer = mkOption {
          type = types.listOf types.str;
          default = [
            ".firefox-wrappe"
            "ipfs"
            "java"
            ".jupyterhub-wra"
            "Logseq"
          ];
          example = [
            ".firefox-wrappe"
            "ipfs"
            "java"
            ".jupyterhub-wra"
            "Logseq"
          ];
          description = ''
            A list of process names that earlyoom should prefer to kill.
          '';
        };

        avoid = mkOption {
          type = types.listOf types.str;
          default = [
            "tlp"
            "bash"
            "mosh-server"
            "sshd"
            "systemd"
            "systemd-logind"
            "systemd-udevd"
            "tmux: client"
            "tmux: server"
          ];
          example = [
            "tlp"
            "bash"
            "mosh-server"
            "sshd"
            "systemd"
            "systemd-logind"
            "systemd-udevd"
            "tmux: client"
            "tmux: server"
            "nix-daemon"
          ];
          description = ''
            A list of process names that earlyoom should avoid killing.
          '';
        };
      };

      config = mkIf cfg.enable {
        # Enable earlyoom to prevent system freezes
        services.earlyoom = {
          enable = false;
          enableNotifications = true;
          extraArgs = [
            "--prefer '^(${concatStringsSep "|" cfg.prefer})$'"
            "--avoid '^(${concatStringsSep "|" cfg.avoid})$'"
          ];
        };

        # OOM configuration:
        systemd = {
          # Let oomd guard desktop apps too, not just nix-daemon. Without this
          # a leaking app can fill swap and thrash the whole session unchecked.
          oomd = {
            enable = true;
            enableUserSlices = true;
          };

          # Create a separate slice for nix-daemon that is
          # memory-managed by the userspace systemd-oomd killer
          slices."nix-daemon".sliceConfig = {
            ManagedOOMMemoryPressure = "kill";
            ManagedOOMMemoryPressureLimit = "75%";
          };
          services."nix-daemon".serviceConfig.Slice = "nix-daemon.slice";

          # If a kernel-level OOM event does occur anyway,
          # strongly prefer killing nix-daemon child processes
          services."nix-daemon".serviceConfig.OOMScoreAdjust = 1000;
        };
      };
    };
}
