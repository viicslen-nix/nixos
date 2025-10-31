{
  lib,
  pkgs,
  config,
  osConfig,
  ...
}: let
  cfg = osConfig.modules.desktop.niri;

  passwordManager =
      if cfg.passwordManager != null
      then (lib.getExe cfg.passwordManager)
      else if (config.modules.functionality.defaults.passwordManager or null) != null
      then (lib.getExe config.modules.functionality.defaults.passwordManager)
      else null;
in{
  programs.niri.settings = {
    prefer-no-csd = true;
    hotkey-overlay.skip-at-startup = true;
    screenshot-path = "~/Pictures/Screenshots/%Y-%m-%dT%H%M%S.png";
    xwayland-satellite.path = "${lib.getExe pkgs.xwayland-satellite}";

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
        {proportion = 0.48;}
        {proportion = 0.65;}
        {proportion = 0.95;}
      ];

      default-column-width = {proportion = 0.95;};
    };

    spawn-at-startup = [
      { argv = ["${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"]; }
      { argv = ["${pkgs.gnome-keyring}/bin/gnome-keyring-daemon" "--start" "--components=secrets"]; }
      { argv = [passwordManager "--silent"]; }
    ];
  };
}
