{
  lib,
  pkgs,
  ...
}: {
  programs.niri.settings = {
    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S.png";

    cursor = {
      hide-when-typing = true;
      hide-after-inactive-ms = 2000;
    };

    input = {
      warp-mouse-to-focus = {
        enable = true;
        mode = "center-xy";
      };

      focus-follows-mouse = {
        enable = true;
        max-scroll-amount = "0%";
      };
    };

    layout = {
      gaps = 16;
      border.width = 4;
      always-center-single-column = true;

      preset-column-widths = [
        {proportion = 0.3;}
        {proportion = 0.45;}
        {proportion = 0.95;}
        {proportion = 1.0;}
      ];

      default-column-width = {proportion = 0.95;};
    };

    hotkey-overlay.skip-at-startup = true;
    xwayland-satellite.path = "${lib.getExe pkgs.xwayland-satellite}";
  };
}
