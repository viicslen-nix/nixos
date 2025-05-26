{
  lib,
  config,
  ...
}: let
  wallpaper = config.stylix.image;
  colors = config.lib.stylix.colors;
in {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = false;
        no_fade_in = false;
      };

      animations = {
        enabled = true;
        bezier = "linear, 1, 1, 0, 0";
        animation = [
          "fadeIn, 1, 5, linear"
          "fadeOut, 1, 5, linear"
          "inputFieldDots, 1, 2, linear"
        ];
      };

      background = {
        monitor = "";
        path = lib.mkForce "screenshot";
        blur_passes = 3;
        blur_size = 8;
      };

      input-field = {
        monitor = "";
        size = "20%, 5%";
        outline_thickness = 3;

        fade_on_empty = false;

        placeholder_text = "Input password...";
        fail_text = "$PAMFAIL";

        dots_spacing = 0.3;

        position = "0, -20";
        halign = "center";
        valign = "center";
      };

      label = [
        {
          monitor = "";
          text = "$TIME12";
          font_size = 40;

          position = "0, 140";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:60000] date +\"%A, %d %B %Y\"";
          font_size = 25;

          position = "0, 80";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  wayland.windowManager.hyprland.settings.bind = [
    "CTRL SHIFT, L, exec, hyprlock"
  ];
}
