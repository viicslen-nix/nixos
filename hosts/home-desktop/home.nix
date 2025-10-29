{
  lib,
  pkgs,
  inputs,
  ...
}: {
  modules = {
    programs = {
      kitty.enable = true;
      zen-browser.enable = true;
    };
  };

  wayland.windowManager.hyprland.settings = {
    cursor = {
      no_hardware_cursors = 1;
      use_cpu_buffer = 0;
    };
  };

  programs = {
    niri.settings.outputs = {
      "DP-2" = {
        scale = 1.5;
        position = {
          x = 0;
          y = 0;
        };
        mode = {
          width = 3840;
          height = 2160;
          refresh = 59.997;
        };
      };
      "HDMI-A-1" = {
        scale = 1.0;
        position = {
          x = 640;
          y = 1440;
        };
        mode = {
          width = 1920;
          height = 1080;
          refresh = 165.001;
        };
        variable-refresh-rate = "on-demand";
        focus-at-startup = true;
      };
    };
  };
}
