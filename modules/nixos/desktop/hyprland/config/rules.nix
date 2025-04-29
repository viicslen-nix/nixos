{lib, ...}: let
  regexList = list: "^(${lib.concatStringsSep "|" list})$";
in {
  wayland.windowManager.hyprland.settings = {
    # layer rules
    layerrule = let
      lowopacity = [
        "bar"
        "notifications"
        "osd"
        "logout_dialog"
      ];

      highopacity = [
        "calendar"
        "system-menu"
        "anyrun"
        "logout_dialog"
      ];

      blurred = lib.concatLists [
        lowopacity
        highopacity
      ];
    in [
      "blur, ${regexList blurred}"
      "xray 1, ${regexList ["bar"]}"
      "ignorealpha 0.5, ${regexList (highopacity ++ ["music"])}"
      "ignorealpha 0.2, ${regexList lowopacity}"
    ];

    workspace = [
      # smart gaps
      "w[tv1], gapsout:0, gapsin:0"
      "f[1], gapsout:0, gapsin:0"
    ];

    # # window rules
    # windowrule = let
    #   float = [
    #     "org.gnome.Calculator"
    #     "org.gnome.design.Palette"
    #     "pavucontrol"
    #     "pwvucontrol"
    #     "nm-connection-editor"
    #     "Color Picker"
    #     "xdg-desktop-portal"
    #     "xdg-desktop-portal-gnome"
    #     "de.haeckerfelix.Fragments"
    #     "com.github.Aylur.ags"
    #   ];
    # in ["float, ${regexList float}"];

    # window rules v2
    windowrulev2 = [
      # Smart Gaps
      "bordersize 0, floating:0, onworkspace:w[tv1]"
      "rounding 0, floating:0, onworkspace:w[tv1]"
      "bordersize 0, floating:0, onworkspace:f[1]"
      "rounding 0, floating:0, onworkspace:f[1]"

      # Fix xwayland apps
      "rounding 0, xwayland:1"

      # Disable shadows when only one window is present
      "noshadow, onworkspace:w[t1]"

      # Throw sharing indicators away
      "workspace special silent, title:^(.*is sharing (your screen|a window)\.)$"

      # Idle inhibit while watching videos
      "idleinhibit focus, class:^(mpv|.+exe|celluloid)$"
      "idleinhibit focus, class:^(firefox|microsoft-edge)$, title:^(.*YouTube.*)$"
      "idleinhibit fullscreen, class:^(firefox|microsoft-edge)$"

      # Make PiP windows stay on top
      "float, title:^(Picture-in-Picture)$"
      "pin, title:^(Picture-in-Picture)$"

      # Transparency
      "opacity 0.90 0.90, class:^(org.gnome.Nautilus|legcord|discord|code|libreoffice-calc)$"

      # GCR Prompter
      "dimaround, class:^(gcr-prompter)$"

      # Polkit
      "float, class:^(polkit-gnome-authentication-agent-1)$"
      "center, class:^(polkit-gnome-authentication-agent-1)$"
      "dimaround, class:^(polkit-gnome-authentication-agent-1)$"
      "size 50% 50%, class:^(polkit-gnome-authentication-agent-1)$"

      # GTK File Chooser
      "float, class:^(xdg-desktop-portal-gtk)$"
      "center, class:^(xdg-desktop-portal-gtk)$"
      "dimaround, class:^(xdg-desktop-portal-gtk)$"
      "size <80% <80%, class:^(xdg-desktop-portal-gtk)$"

      # 1Password
      "float, title:(1Password)"
      "center, title:(1Password)"

      # Microsoft Edge
      "tile, class:^(microsoft-edge)$"

      # JetBrains IDEs
      "center, class:^(.*jetbrains.*)$, title:^(Confirm Exit|Open Project|win424|win201|splash)$"
      "size <90% <80%, class:^(.*jetbrains.*)$, title:^(win.*)$"
      "opacity 0.90 0.90, class:^(.*jetbrains.*)$"

      # Satty
      "float, class:^(com.gabm.satty)$"
      "pseudo, class:^(com.gabm.satty)$"
      "size 90% 90%, class:^(com.gabm.satty)$"

      # LibreOffice
      "float, class:^(soffice)$, title:^(Text Import -)(.*)$"
    ];
  };
}
