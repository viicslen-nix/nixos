{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  # home.file.".config/marble/theme.json".text = with config.lib.stylix.colors; ''
  # '';

  wayland.windowManager.hyprland.settings = {
    exec-once = lib.mkAfter [
      "marble"
    ];
  };
}
