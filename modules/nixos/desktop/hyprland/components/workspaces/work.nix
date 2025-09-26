{pkgs}:
with pkgs;
  writeShellApplication {
    name = "hyprflow-work";
    runtimeInputs = [hyprland];
    text = ''
      ${hyprland}/bin/hyprctl dispatch exec "[workspace 1 silent] zen-beta"
      ${hyprland}/bin/hyprctl dispatch exec "[workspace 11 silent] legcord"
      ${hyprland}/bin/hyprctl dispatch exec "[workspace 11 silent] kitty"
      ${hyprland}/bin/hyprctl dispatch exec "[workspace 12 silent] code"
      ${hyprland}/bin/hyprctl dispatch exec "[workspace 12 silent] kitty"
    '';
    meta.description = "Hyprland workspace setup script for work environment";
  }
