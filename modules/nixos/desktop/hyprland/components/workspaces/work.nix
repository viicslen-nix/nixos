{pkgs}:
pkgs.writeShellScript "hyprsflow-work" ''
  ${pkgs.hyprland}/bin/hyprctl dispatch exec "[workspace 1 silent] kitty"
  ${pkgs.hyprland}/bin/hyprctl dispatch exec "[workspace 2 silent] legcord"
  ${pkgs.hyprland}/bin/hyprctl dispatch exec "[workspace 3 silent] code"
  ${pkgs.hyprland}/bin/hyprctl dispatch exec "[workspace 11 silent] microsoft-edge"
  ${pkgs.hyprland}/bin/hyprctl dispatch exec "[workspace 12 silent] phpstorm"
''
