{
  # wayland.windowManager.hyprland.bind = builtins.concatLists (builtins.genList (
  #   x: let
  #     ws = let
  #       c = (x + 1) / 10;
  #     in
  #       builtins.toString (x + 1 - (c * 10));
  #   in [
  #     "$mod, ${ws}, workspace, ${toString (x + 1)}"
  #     "$mod SHIFT, ${ws}, movetoworkspacesilent, ${toString (x + 1)}"
  #   ]
  # )
  # 10);

  wayland.windowManager.hyprland = {
    settings = {
      # modifier key
      "$mod" = "SUPER";

      # applications
      "$terminal" = "uwsm app -- ghostty";
      "$browser" = "uwsm app -- microsoft-edge";
      "$fileManager" = "uwsm app -- nautilus";
      "$passwordManager" = "uwsm app -- 1password --quick-access";

      # mouse movements
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod ALT, mouse:272, resizewindow"
      ];

      # binds
      bind = [
        # compositor commands
        "$mod, Q, killactive,"
        "$mod, F, fullscreen,"
        "$mod, G, togglegroup,"
        "$mod, R, togglesplit,"
        "$mod, T, togglefloating,"
        "$mod, P, pin,"
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

        # Scrachpads
        "$mod CTRL, T, exec, pypr toggle term"
        "$mod CTRL, V, exec, pypr toggle volume"

        # system
        "$mod, L, exec, loginctl lock-session"

        # screenshot
        "$mod SHIFT ALT, S, exec, grimblast --notify --cursor copysave screen"

        # applications
        "$mod, Return, exec, $terminal"
        "$mod, B, exec, $browser"
        "$mod, E, exec, $fileManager"
        "CTRL SHIFT, Space, exec, $passwordManager"

        # submaps
        "$mod, Space, submap, apps"
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

    extraConfig = ''
      # apps
      submap = apps

      binde = , p, exec, uwsm app -- phpstorm
      binde = , d, exec, uwsm app -- datagrip
      binde = , w, exec, uwsm app -- webstorm
      binde = , s, exec, uwsm app -- slack
      binde = , l, exec, uwsm app -- legcord
      binde = , f, exec, uwsm app -- firefox
      binde = , c, exec, uwsm app -- code
      binde = , e, exec, uwsm app -- nautilus
      binde = , t, exec, uwsm app -- kitty
      binde = , b, exec, uwsm app -- microsoft-edge

      bind = , escape, submap, reset
      bind = , catchall, submap, reset
      submap = reset
    '';
  };
}
