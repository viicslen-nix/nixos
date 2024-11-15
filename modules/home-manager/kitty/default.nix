{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.features.kitty;
in {
  options.features.kitty = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable kitty terminal emulator";
    };
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;

      shellIntegration.enableZshIntegration = true;

      settings = {
        # shell = "zsh -l -c 'tmux attach || tmux'";
        wayland_titlebar_color = "background";
        background_opacity = lib.mkForce "0.8";
        dynamic_background_opacity = true;
        remember_window_size = true;
        background_blur = 5;
        font_size = "11.0";
        tab_bar_align = "center";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";
      };

      extraConfig = ''
        modify_font cell_height 150%
        modify_font strikethrough_position 150%
      '';
    };

    dconf.settings."org/gnome/shell/extensions/blur-my-shell/applications" = {
      whitelist = ["kitty"];
    };
  };
}
