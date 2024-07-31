{config, pkgs, ...}: let
  variant = "dark";
  pointer = config.stylix.cursor;
  colorScheme = config.lib.stylix.colors;
  scripts = import ./scripts.nix {inherit pkgs;};
in {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1,2560x1600@60,0x0,1.6"
      "HDMI-A-1,preferred,auto-up,1"
      ",preferred,auto,1"
    ];

    workspace = [
      "1, monitor:HDMI-A-1, default:true"
    ];

    env = [
      "NIXOS_OZONE_WL,1"
      "NIXPKGS_ALLOW_UNFREE,1"

      "XDG_CURRENT_DESKTOP,Hyprland"
      "XDG_SESSION_DESKTOP,Hyprland"

      "XDG_SESSION_TYPE,wayland"
      "CLUTTER_BACKEND,wayland"
      "GDK_BACKEND,wayland,x11"
      "SDL_VIDEODRIVER,wayland"

      # "GBM_BACKEND,nvidia-drm"
      # "LIBVA_DRIVER_NAME,nvidia"
      # "__GLX_VENDOR_LIBRARY_NAME,nvidia"

      "QT_QPA_PLATFORM,wayland"
      "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
      "QT_AUTO_SCREEN_SCALE_FACTOR,1"

      "MOZ_ENABLE_WAYLAND,1"

      "GDK_SCALE,1.6"
      "XCURSOR_SIZE,${toString pointer.size}"
    ];

    exec-once = [
      "dbus-update-activation-environment --systemd --all"
      "systemctl --user import-environment QT_QPA_PLATFORMTHEME WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

      "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      "gnome-keyring-daemon --start --components=secrets"

      "hyprctl setcursor ${pointer.name} ${toString pointer.size}"

      "killall -q waybar;sleep .5 && waybar"
      "killall -q swaync;sleep .5 && swaync"
      "killall -q 1password;sleep .5 && 1password --silent"
      "killall -q mullvad-gui;sleep .5 && mullvad-gui --silent"
      "nm-applet --indicator"

      scripts.handleMonitorConnect.outPath
    ];

    general = {
      gaps_in = 5;
      gaps_out = 5;
      border_size = 1;

      allow_tearing = true;
      resize_on_border = true;
    };

    decoration = {
      rounding = 16;
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

      drop_shadow = true;
      shadow_ignore_window = true;
      shadow_offset = "0 2";
      shadow_range = 20;
      shadow_render_power = 3;
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

    group = {
      groupbar = {
        font_size = 16;
        gradients = false;
      };
    };

    input = {
      kb_layout = "us";

      # focus change on cursor move
      follow_mouse = 1;
      mouse_refocus = false;

      accel_profile = "flat";
      touchpad.scroll_factor = 0.1;
    };

    dwindle = {
      # keep floating dimentions while tiling
      pseudotile = true;
      preserve_split = true;
    };

    misc = {
      # disable auto polling for config file changes
      disable_autoreload = true;

      force_default_wallpaper = 0;

      # disable dragging animation
      animate_mouse_windowdragging = false;

      # enable variable refresh rate (effective depending on hardware)
      vrr = 1;

      # we do, in fact, want direct scanout
      no_direct_scanout = false;
    };

    # touchpad gestures
    gestures = {
      workspace_swipe = true;
      workspace_swipe_forever = true;
    };

    xwayland.force_zero_scaling = true;

    debug.disable_logs = false;

    plugin = {
      csgo-vulkan-fix = {
        res_w = 1280;
        res_h = 800;
        class = "cs2";
      };

      hyprbars = {
        bar_height = 20;
        bar_precedence_over_border = true;

        # order is right-to-left
        hyprbars-button = [
          # close
          "rgb(ff0000), 15, , hyprctl dispatch killactive"
          # maximize
          "rgb(ffff00), 15, , hyprctl dispatch fullscreen 1"
        ];
      };

      hyprexpo = {
        columns = 3;
        gap_size = 4;
        bg_col = "rgb(000000)";

        enable_gesture = true;
        gesture_distance = 300;
        gesture_positive = false;
      };

      split-monitor-workspaces = {
        count = 10;
        keep_focused = 0;
        enable_notifications = 0;
      };
    };
  };
}
