{
  lib,
  config,
  osConfig,
  ...
}:
with lib; let
  hyprConfig = osConfig.modules.desktop.hyprland;
in {
  home.sessionVariables = hyprConfig.globalVariables;

  xdg.configFile = mkIf osConfig.programs.hyprland.withUWSM {
    "uwsm/env".text = concatMapAttrsStringSep "\n" (name: value: "export ${name}=${value}") hyprConfig.globalVariables;
    "uwsm/env-hyprland".text = concatMapAttrsStringSep "\n" (name: value: "export ${name}=${value}") hyprConfig.hyprVariables;
  };

  wayland.windowManager.hyprland.settings.env = concatLists [
    (mapAttrsToList (name: value: "${name},${value}") hyprConfig.globalVariables)
    (mapAttrsToList (name: value: "${name},${value}") hyprConfig.hyprVariables)
  ];
}
