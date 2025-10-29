{
  inputs,
  pkgs,
  lib,
  ...
}: {
  home.autostart = [
    pkgs.jetbrains-toolbox
  ];

  home.file.".config/hypr/pyprland.toml".text = lib.mkAfter ''
    [monitors.placement."LW9AA0048525"]
    rightOf = "DP-1"
    transform = 3
  '';

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DP-1, 1920x1080@59.99, 0x0, 1, vrr, 0"
      "DP-2, 1920x1080@59.99, 1920x0, 1, transform, 3, vrr, 0"
      ", preferred, auto, 1"
    ];

    cursor.no_hardware_cursors = 1;
  };

  modules.programs = {
    ray.enable = true;
    kitty.enable = true;
    tinkerwell.enable = true;
    zen-browser.enable = true;
  };

  programs.niri.settings.outputs = {
    "DP-1" = {
      scale = 1.0;
      position = {
        x = 0;
        y = 0;
      };
      mode = {
        width = 1920;
        height = 1080;
        refresh = 59.997;
      };
    };
    "DP-2" = {
      scale = 1.0;
      position = {
        x = 1920;
        y = 0;
      };
      mode = {
        width = 1920;
        height = 1080;
        refresh = 59.997;
      };
      focus-at-startup = true;
      transform.rotation = 270;
    };
  };
}
