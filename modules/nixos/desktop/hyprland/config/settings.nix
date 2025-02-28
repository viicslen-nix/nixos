{
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1,2560x1600@60,0x0,1.6"
      ",preferred,auto,1"
    ];

    exec-once = [
      "dbus-update-activation-environment --systemd --all"
      "systemctl --user import-environment QT_QPA_PLATFORMTHEME WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

      "uwsm app -- ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      "uwsm app -- gnome-keyring-daemon --start --components=secrets"

      "uwsm app -- pypr"
      "uwsm app -- swww-daemon"
      "uwsm app -- 1password --silent"
      "uwsm app -- mullvad-gui --silent"

      "uwsm app -- wl-paste --type text --watch cliphist store"
      "uwsm app -- wl-paste --type image --watch cliphist store"
    ];

    general = {
      gaps_in = 5;
      gaps_out = 5;
      border_size = 2;

      allow_tearing = true;
      resize_on_border = true;
      extend_border_grab_area = 20;
    };

    decoration = {
      rounding = 16;

      dim_inactive = true;
      dim_strength = 0.1;

      blur = {
        enabled = true;
        brightness = 1.0;
        contrast = 1.0;
        noise = 0.01;

        vibrancy = 0.2;
        vibrancy_darkness = 0.5;

        passes = 4;
        size = 7;

        popups = true;
        popups_ignorealpha = 0.2;
      };

      shadow = {
        enabled = true;
        range = 20;
        offset = "0 2";
        render_power = 3;
        ignore_window = true;
      };
    };

    animations = {
      enabled = true;
      animation = [
        "border, 1, 2, default"
        "fade, 1, 4, default"
        "windows, 1, 3, default, popin 80%"
        "workspaces, 1, 2, default, slide"
      ];
    };

    group.groupbar = {
      font_size = 16;
      gradients = false;
    };

    input = {
      kb_layout = "us";

      follow_mouse = 1;
      mouse_refocus = false;

      accel_profile = "flat";
      touchpad.scroll_factor = 0.1;
    };

    dwindle = {
      pseudotile = true;
      preserve_split = true;
    };

    misc = {
      animate_mouse_windowdragging = false;
      initial_workspace_tracking = 1;
      disable_autoreload = true;
      vrr = 1;
    };

    gestures = {
      workspace_swipe = true;
      workspace_swipe_forever = true;
    };

    xwayland = {
      force_zero_scaling = true;
    };

    render = {
      direct_scanout = 2;
      explicit_sync = 2;
    };

    cursor = {
      no_hardware_cursors = true;
      use_cpu_buffer = 1;
    };

    debug.disable_logs = false;
  };
}
