{
  lib,
  pkgs,
  config,
  osConfig,
  ...
}: let
  cfg = osConfig.modules.desktop.niri;
in {
  xdg.configFile."DankMaterialShell/stylix.json".source = with config.lib.stylix.colors.withHashtag;
    lib.mkIf config.stylix.enable (
      pkgs.writers.writeJSON "custom-theme.json" {
        "name" = "Stylix";
        "primary" = base0C;
        "primaryText" = base00;
        "primaryContainer" = base0D;
        "secondary" = base0E;
        "surface" = base00;
        "surfaceText" = base05;
        "surfaceVariant" = base01;
        "surfaceVariantText" = base04;
        "surfaceTint" = base0C;
        "background" = base00;
        "backgroundText" = base07;
        "outline" = base03;
        "surfaceContainer" = base01;
        "surfaceContainerHigh" = base02;
        "error" = base08;
        "warning" = base0A;
        "info" = base0D;
      }
    );

  programs.dankMaterialShell = {
    enable = true;
    niri = {
      enableSpawn = true;
      enableKeybinds = true;
    };
  };

  programs.niri.settings = let
    passwordManager = with lib;
      if cfg.passwordManager != null
      then (getExe cfg.passwordManager)
      else if (config.modules.functionality.defaults.passwordManager or null) != null
      then (getExe config.modules.functionality.defaults.passwordManager)
      else null;
  in {
    spawn-at-startup = [
      {argv = [passwordManager "--silent"];}
    ];

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
      center-focused-column = "on-overflow";

      preset-column-widths = [
        {proportion = 0.3;}
        {proportion = 0.45;}
        {proportion = 0.9;}
        {proportion = 1.0;}
      ];

      default-column-width = {proportion = 0.9;};
    };

    hotkey-overlay.skip-at-startup = true;
    xwayland-satellite.path = "${lib.getExe pkgs.xwayland-satellite}";
  };
}
