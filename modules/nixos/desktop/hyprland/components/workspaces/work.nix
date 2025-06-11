{pkgs}:
pkgs.writeShellScript "hyprflow-work" ''
  ${pkgs.hyprland}/bin/hyprctl dispatch exec "[workspace 1 silent] zen-beta"
  ${pkgs.hyprland}/bin/hyprctl dispatch exec "[workspace 11 silent] zen-beta"
  ${pkgs.hyprland}/bin/hyprctl dispatch exec "[workspace 12 silent] legcord"
  ${pkgs.hyprland}/bin/hyprctl dispatch exec "[workspace 12 silent] kitty"
  ${pkgs.hyprland}/bin/hyprctl dispatch exec "[workspace 13 silent] code"
  ${pkgs.hyprland}/bin/hyprctl dispatch exec "[workspace 13 silent] kitty"
''
