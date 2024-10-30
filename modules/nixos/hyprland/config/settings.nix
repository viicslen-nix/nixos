{
  config,
  pkgs,
  inputs,
  ...
}: let
  pointer = config.stylix.cursor;
in {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1,2560x1600@60,0x0,1.6"
      ",preferred,auto,1"
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

      "killall -q pypr;sleep .5 && pypr"
      "killall -q swww-daemon;sleep .5 && swww-daemon"
      "killall -q 1password;sleep .5 && 1password --silent"
      "killall -q mullvad-gui;sleep .5 && mullvad-gui --silent"

      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"

      "swww img ${inputs.wallpapers}/wallpapers/Lofi-Urban-Nightscape.png"
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
      drop_shadow = true;
      shadow_ignore_window = true;
      shadow_offset = "0 2";
      shadow_range = 20;
      shadow_render_power = 3;

      dim_inactive = true;
      dim_strength = 0.1;

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
      vrr = 1;
    };

    gestures = {
      workspace_swipe = true;
      workspace_swipe_forever = true;
    };

    render.direct_scanout = true;
    debug.disable_logs = false;
  };
}
