{pkgs, ...}: let
  screenshot = flags: ''grim -g "$(slurp ${flags})" -t ppm - | satty --filename - --fullscreen --output-filename ~/Pictures/Screenshots/satty-$(date '+%Y%m%d-%H:%M:%S').png'';

  # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
  workspaces = builtins.concatLists (builtins.genList (
      x: let
        ws = let
          c = (x + 1) / 10;
        in
          builtins.toString (x + 1 - (c * 10));
      in [
        "$mod, ${ws}, split-workspace, ${toString (x + 1)}"
        "$mod SHIFT, ${ws}, split-movetoworkspacesilent, ${toString (x + 1)}"
      ]
    )
    10);
in {
  wayland.windowManager.hyprland.settings = {
    # modifier key
    "$mod" = "SUPER";

    # applications
    "$terminal" = "${pkgs.kitty}/bin/kitty";
    "$fileManager" = "nautilus";

    # mouse movements
    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
      "$mod ALT, mouse:272, resizewindow"
    ];

    # binds
    bind =
      [
        # compositor commands
        "$mod, Q, killactive,"
        "$mod, F, fullscreen,"
        "$mod, G, togglegroup,"
        "$mod, R, togglesplit,"
        "$mod, T, togglefloating,"
        "$mod, P, pseudo,"
        "$mod ALT, ,resizeactive,"

        # cycle monitors
        "$mod SHIFT, Left, focusmonitor, l"
        "$mod SHIFT, Right, focusmonitor, r"

        # send focused workspace to left/right monitors
        "$mod SHIFT ALT, Left, movecurrentworkspacetomonitor, l"
        "$mod SHIFT ALT, Right, movecurrentworkspacetomonitor, r"

        # cycle workspaces
        "$mod, Left, workspace, m-1"
        "$mod, Right, workspace, m+1"

        # move focus
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # minimize
        "$mod CTRL, M, togglespecialworkspace, minimized"
        "$mod, M, exec, pypr toggle_special minimized"

        # system
        "$mod, Escape, exec, wlogout -p layer-shell"
        "$mod, L, exec, loginctl lock-session"
        "$mod SHIFT, N, exec, swaync-client -op"
        "$mod SHIFT, W, exec, killall -q waybar;sleep .5 && waybar"
        "$mod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"

        # screenshot
        "$mod SHIFT, S, exec, ${screenshot ""}"
        "$mod SHIFT CTRL, S, exec, ${screenshot "-o -r"}"
        "$mod SHIFT ALT, S, exec, grimblast --notify --cursor copysave screen"

        # utilities
        "$mod, Return, exec, $terminal"
        "Control_L&Shift_L, Space, exec, 1password --quick-access"
        
        # Scrachpads
        "$mod CTRL, T, exec, pypr toggle term"
        "$mod CTRL, V, exec, pypr toggle volume" 
      ]
      ++ workspaces;

    bindr = [
      # launcher
      "$mod, SUPER_L, exec, $launcher"
    ];

    bindl = [
      # media controls
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioPrev, exec, playerctl previous"
      ", XF86AudioNext, exec, playerctl next"

      # volume
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
    ];

    bindle = [
      # volume
      ", XF86AudioRaiseVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%-"

      # backlight
      ", XF86MonBrightnessUp, exec, brillo -q -u 300000 -A 5"
      ", XF86MonBrightnessDown, exec, brillo -q -u 300000 -U 5"
    ];
  };
}
