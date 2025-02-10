{
  lib,
  config,
  ...
}:
with lib; let
  name = "kitty";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;

      shellIntegration.enableZshIntegration = true;

      settings = {
        wayland_titlebar_color = "background";
        background_opacity = lib.mkForce "0.8";
        dynamic_background_opacity = true;
        remember_window_size = true;
        background_blur = 5;
        font_size = "11.0";
        tab_bar_align = "center";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";
        cursor_trail = 1;
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
