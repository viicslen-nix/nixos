{pkgs}:
pkgs.writeShellScript "hyprsflow-work" ''
  hyprctl dispatch exec [workspace 1 silent] kitty
  hyprctl dispatch exec [workspace 2 silent] legcord
  hyprctl dispatch exec [workspace 3 silent] code
  hyprctl dispatch exec [workspace 11 silent] microsoft-edge
  hyprctl dispatch exec [workspace 12 silent] phpstorm
''
