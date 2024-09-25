let
  ags = "ags -b hypr";
in {
  wayland.windowManager.hyprland.settings = {
    "$launcher" = "${ags} -t launcher";

    exec-once = [
      "killall -q ags -b hypr;sleep .5 && ags -b hypr"
    ];

    bind = [
      "mod, Tab, exec, ${ags} -t overview"
      "$mod CTRL SHIFT, R, exec, ${ags} quit; ${ags}"
      ",XF86PowerOff, exec, ${ags} -r 'powermenu.shutdown()'"
    ];
  };
}