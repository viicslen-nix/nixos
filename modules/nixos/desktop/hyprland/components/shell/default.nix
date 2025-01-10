{pkgs, ...}: {
  home.packages = with pkgs; [
    inputs.shell.default
  ];

  xdg.configFile."marble".source = ./config;

  wayland.windowManager.hyprland.settings = let
    shell = "marble -b hypr";
  in {
    "$launcher" = "${shell} -t launcher";

    exec-once = [
      "uwsm app -- ${shell}"
    ];

    bindr = [
      "$mod, SUPER_L, exec, ${shell} -t launcher"
    ];

    bind = [
      ",XF86PowerOff, exec, ${shell} -t 'powermenu'"
    ];
  };
}
