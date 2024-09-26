{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: let
  # Use `mkLiteral` for string-like values that should show without
  # quotes, e.g.:
  # {
  #   foo = "abc"; => foo: "abc";
  #   bar = mkLiteral "abc"; => bar: abc;
  # };
  inherit (config.lib.formats.rasi) mkLiteral;
in {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    terminal = "${pkgs.kitty}/bin/kitty";
    theme = lib.mkForce {
      "@import" = "${inputs.rofi-collections}/material/material.rasi";

      "window" = {
        transparency = "real";
        border-color = mkLiteral "#FFFFFF";
        border-radius = mkLiteral "15px";
        background-color = mkLiteral "#282c34d0";
      };

      "element-icon" = {
        size = mkLiteral "20px";
      };
    };
  };

  wayland.windowManager.hyprland.settings = {
    "$launcher" = "${pkgs.rofi-wayland}/bin/rofi -show drun";

    bind = [
      "$mod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
    ];
  };
}
