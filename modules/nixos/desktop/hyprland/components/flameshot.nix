{pkgs, lib, ...}: with lib; {
  wayland.windowManager.hyprland.settings = {
    windowrulev2 = [
      "move 0 0,class:(flameshot),title:(flameshot)"
      "pin,class:(flameshot),title:(flameshot)"
      "fullscreenstate,class:(flameshot),title:(flameshot)"
      "float,class:(flameshot),title:(flameshot)"
    ];
    bind = [
      "$mod SHIFT ALT, S, exec, ${getExe' pkgs.flameshot} gui"
    ];
  }
}
