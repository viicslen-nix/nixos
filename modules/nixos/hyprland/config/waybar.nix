{
  wayland.windowManager.hyprland.settings = {
    "$launcher" = "${pkgs.rofi-wayland}/bin/rofi -show drun";

    exec-once = [
      "killall -q waybar;sleep .5 && waybar"
    ];
  };
}