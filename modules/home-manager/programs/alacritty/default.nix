{
  lib,
  config,
  ...
}:
with lib; let
  name = "alacritty";
  namespace = "features";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

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
