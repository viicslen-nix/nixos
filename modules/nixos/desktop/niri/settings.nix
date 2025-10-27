{
  lib,
  pkgs,
  ...
}: {
  programs.niri.settings = {
    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S.png";

    layout = {
      gaps = 16;
      border.width = 4;
      always-center-single-column = true;
    };

    xwayland-satellite.path = "${lib.getExe pkgs.xwayland-satellite-unstable}";
  };
}
