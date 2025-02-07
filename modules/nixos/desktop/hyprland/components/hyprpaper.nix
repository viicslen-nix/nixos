{
  pkgs,
  config,
  ...
}: let
  wallpaper = config.stylix.image;
in {
  home.packages = with pkgs; [
    hyprpaper
  ];

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;

      preload = [wallpaper];

      wallpaper = [",${wallpaper}"];
    };
  };
}
