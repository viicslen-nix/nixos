{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.features.alacritty;
in {
  options.features.alacritty = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable alacritty";
    };

    tmuxIntegration = mkOption {
      type = types.bool;
      default = false;
      description = "Enable TMUX integration";
    };
  };

  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        live_config_reload = true;

        shell = mkIf cfg.tmuxIntegration {
          program = "zsh";
          args = ["-l" "-c" "tmux attach || tmux"];
        };

        font = {
          offset = {
            y = 0;
            x = 0;
          };
          
          glyph_offset = {
            y = 0;
            x = 0;
          };
        };

        window.startup_mode = "Maximized";
      };
    };
  };
}
