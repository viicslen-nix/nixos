{pkgs, lib, ...}: with lib; {
  home.file.".config/swappy/config".text = ''
    [Default]
    save_dir=$HOME/Pictures/Screenshots
    save_filename_format=screenshot-%Y%m%d-%H%M%S.png
    line_size=5
    text_size=20
    paint_mode=brush
    early_exit=true
    auto_save=true
  '';

  wayland.windowManager.hyprland.settings.bind = let
    hyprshot = mode: "${getExe' pkgs.hyprshot} -m ${mode} --freeze";
  in [
    "$mod SHIFT, S, exec, ${hyprshot "region"}"
    "$mod SHIFT CTRL, S, exec, ${hyprshot "active -m output"}"
  ];
}
