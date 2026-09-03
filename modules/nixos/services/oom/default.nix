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
        # Enable earlyoom to prevent system freezes.
        #
        # This is the only guard that works once the box is already thrashing:
        # it polls free RAM *and free swap* from userspace and SIGTERMs the
        # largest process, where the kernel OOM killer never fires at all
        # (31G of swap means it always has somewhere to page to) and oomd needs
        # 30s of sustained cgroup PSI plus enough CPU to act on it.
        #
        # Swap here is roughly the size of RAM, so freeSwapThreshold has to be
        # high: earlyoom acts only when free memory AND free swap are both under
        # their thresholds, and with 31G of swap a 10% swap floor means waiting
        # until 28G has already been paged out — long past the livelock.
        services.earlyoom = {
          enable = true;
          enableNotifications = true;
          freeMemThreshold = 8;
          freeMemKillThreshold = 4;
          freeSwapThreshold = 50;
          freeSwapKillThreshold = 25;
          # NOTE: extraArgs goes through lib.escapeShellArgs, so a flag and its
          # value must be separate list entries. "--prefer '^(x)$'" as one
          # string arrives as a single argv and earlyoom fails to start.
          extraArgs = [
            "--prefer"
            "^(${concatStringsSep "|" cfg.prefer})$"
            "--avoid"
            "^(${concatStringsSep "|" cfg.avoid})$"
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
            # Without this, `oomctl` reports an empty "Swap Monitored CGroups"
            # list and oomd's 90%-swap-used rule applies to nothing at all.
            ManagedOOMSwap = "kill";

            # Hard bound on the rebuild. Nothing capped nix-daemon before
            # (MemoryMax=infinity), so a runaway eval or a wide parallel build
            # could take the whole 31G and livelock the desktop. MemoryHigh
            # throttles it into reclaim first; MemoryMax kills it and leaves
            # ~17G for the session instead of taking the machine down.
            MemoryHigh = "10G";
            MemoryMax = "14G";
          };
          services."nix-daemon".serviceConfig.Slice = "nix-daemon.slice";

          # If a kernel-level OOM event does occur anyway,
          # strongly prefer killing nix-daemon child processes
          services."nix-daemon".serviceConfig.OOMScoreAdjust = 1000;
        };
      };
    };
}
