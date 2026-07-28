{
  lib,
  pkgs,
  osConfig,
  homeModules,
  ...
}: {
  imports = with homeModules; [
    programs.ray
    programs.kitty
    programs.tinkerwell
    programs.zen-browser
    programs.vivaldi
    programs.webapps
  ];

  home.file.".config/hypr/pyprland.toml".text = lib.mkAfter ''
    [monitors.placement."LW9AA0048525"]
    rightOf = "DP-1"
    transform = 1
  '';

  home.autostart = [
    {
      package = pkgs.mullvad-vpn;
      args = ["--silent"];
      delay = 5;
    }
    {
      package = pkgs.jetbrains-toolbox;
      delay = 5;
    }
  ];

  wayland.windowManager.hyprland.settings = lib.mkIf osConfig.programs.hyprland.enable {
    monitor = [
      "DP-1, 1920x1080@59.99, 0x0, 1, vrr, 0"
      "DP-2, 1920x1080@59.99, 1920x0, 1, transform, 3, vrr, 0"
      ", preferred, auto, 1"
    ];
  };

  programs.niri.settings = lib.mkIf osConfig.programs.niri.enable {
    workspaces = {
      "browser" = {
        name = "Browser";
        open-on-output = "DP-1";
      };
      "editor" = {
        name = "Editor";
        open-on-output = "DP-1";
      };
      "communication" = {
        name = "Communication";
        open-on-output = "DP-2";
      };
      "system" = {
        name = "System";
        open-on-output = "DP-2";
      };
    };

    binds = {
      "Mod+F1".action.spawn = ["zen-browser"];
      "Mod+F2".action.spawn = ["phpstorm"];
      "Mod+F3".action.spawn = ["legcode" "--split=top" "kitty" "--split=bottom"];
      "Mod+F4".action.spawn = ["code" "--split=top" "kitty" "--split=bottom"];
    };
  };

  programs.dank-material-shell.niri.includes.filesToInclude = [
    "custom"
  ];
}
