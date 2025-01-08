{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; let
  name = "tmux";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "tmux");
  };

  config.programs.tmux = mkIf cfg.enable {
    enable = true;
    shortcut = "Space";
    mouse = true;
    baseIndex = 1;
    keyMode = "vi";
    escapeTime = 1;
    historyLimit = 10000;
    aggressiveResize = true;
    tmuxinator.enable = true;

    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = "set -g @resurrect-strategy-nvim 'session'";
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'off'
          set -g @continuum-save-interval '60' # minutes
        '';
      }
      {
        plugin = tmuxPlugins.mkTmuxPlugin {
          pluginName = "tokyo-night";
          rtpFilePath = "tokyo-night.tmux";
          version = "v1.5.5";
          src = inputs.tmux-tokyo-night;
        };
        extraConfig = ''
          set -g @tokyo-night-tmux_theme "storm" # options: night, storm, day
          set -g @tokyo-night-tmux_show_datetime 0
          set -g @tokyo-night-tmux_path_format "relative"
          set -g @tokyo-night-tmux_show_git 1
          set -g @tokyo-night-tmux_show_wbg 1
          set -g status-justify left
        '';
      }
      {
        plugin = tmuxPlugins.mkTmuxPlugin {
          pluginName = "tmux-1password";
          rtpFilePath = "plugin.tmux";
          version = "master";
          src = inputs.tmux-1password;
        };
      }
    ];

    extraConfig = ''
      ${builtins.unsafeDiscardStringContext (builtins.readFile ./tmux.conf)}
    '';
  };
}
