{
  config,
  lib,
  ...
}: let
  colorScheme = config.lib.stylix.colors;

  font_family = "Inter";
in {
  programs.hyprlock = {
    enable = lib.mkForce true;

    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = false;
        no_fade_in = true;
      };

      # backgrounds = [
      #   {
      #     monitor = "";
      #     path = wallpaper;
      #   }
      # ];

      input-fields = [
        {
          monitor = "eDP-1";

          size = {
            width = 300;
            height = 50;
          };

          outline_thickness = 2;

          outer_color = "rgb(${colorScheme.base00})";
          inner_color = "rgb(${colorScheme.base01})";
          font_color = "rgb(${colorScheme.base05})";

          fade_on_empty = false;
          # placeholder_text = ''<span font_family="${font_family}" foreground="##${c.primary_container}">Password...</span>'';

          dots_spacing = 0.3;
          dots_center = true;
        }
      ];

      labels = [
        {
          monitor = "";
          text = "$TIME";
          inherit font_family;
          font_size = 50;
          color = "rgb(${colorScheme.base00})";

          position = {
            x = 0;
            y = 80;
          };

          valign = "center";
          halign = "center";
        }
      ];
    };
  };
}
