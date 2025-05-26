{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  home.file.".config/flameshot/flameshot.ini".text = with config.lib.stylix.colors; ''
    [General]
    allowMultipleGuiInstances=true
    autoCloseIdleDaemon=true
    contrastOpacity=188
    copyPathAfterSave=true
    disabledTrayIcon=true
    drawColor=#ff0000
    savePathFixed=true
    showDesktopNotification=false
    showStartupLaunchMessage=false
    contrastUiColor=#${base0A}
    uiColor=#${base00}
  '';

  wayland.windowManager.hyprland.settings = {
    windowrulev2 = [
      "move 0 0,class:(flameshot),title:(flameshot)"
      "pin,class:(flameshot),title:(flameshot)"
      "fullscreenstate,class:(flameshot),title:(flameshot)"
      "float,class:(flameshot),title:(flameshot)"
    ];
    bind = let
      flameshot = pkgs.flameshot.override {enableWlrSupport = true;};
    in [
      "$mod SHIFT ALT, S, exec, ${getExe flameshot} gui"
    ];
  };
}
