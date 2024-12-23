{config, ...}: let
  wallpaper = config.stylix.image;
  colors = config.lib.stylix.colors;
in {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 10;
        hide_cursor = true;
        no_fade_in = false;
      };
      background = {
        blur_passes = 3;
        blur_size = 8;
        path = wallpaper;
      };
      input-field = {
        monitor = "";
        size = "200, 50";
        position = "0, -80";
        dots_center = true;
        fade_on_empty = false;
        outline_thickness = 5;
        placeholder_text = "Password...";
        shadow_passes = 2;

        outer_color = "rgb(${colors.base00})";
        inner_color = "rgb(${colors.base01})";
        font_color = "rgb(${colors.base05})";
      };
      labels = {
        monitor = "";
        text = "$TIME";
        font_size = 50;
        color = "rgb(${colors.base00})";

        position = {
          x = 0;
          y = 80;
        };

        valign = "center";
        halign = "center";
      };
    };
  };
}
