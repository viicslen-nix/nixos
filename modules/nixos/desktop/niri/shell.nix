{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
  ];

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
}
