{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  feature = "oom";
  namespace = "features";
  cfg = config.${namespace}.${feature};
in {
  options.${namespace}.${feature} = {
    enable = mkEnableOption (mdDoc feature);

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
      ];
      description = ''
        A list of process names that earlyoom should avoid killing.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Enable earlyoom to prevent system freezes
    services.earlyoom = {
      enable = true;
      enableNotifications = true;
      extraArgs = let
        catPatterns = patterns: builtins.concatStringsSep "|" patterns;
        preferPatterns = cfg.prefer;
        avoidPatterns = cfg.avoid;
      in [
        "--prefer '^(${catPatterns preferPatterns})$'"
        "--avoid '^(${catPatterns avoidPatterns})$'"
      ];
    };

    # OOM configuration:
    systemd = {
      # Create a separate slice for nix-daemon that is
      # memory-managed by the userspace systemd-oomd killer
      slices."nix-daemon".sliceConfig = {
        ManagedOOMMemoryPressure = "kill";
        ManagedOOMMemoryPressureLimit = "50%";
      };
      services."nix-daemon".serviceConfig.Slice = "nix-daemon.slice";

      # If a kernel-level OOM event does occur anyway,
      # strongly prefer killing nix-daemon child processes
      services."nix-daemon".serviceConfig.OOMScoreAdjust = 1000;
    };
  };
}
