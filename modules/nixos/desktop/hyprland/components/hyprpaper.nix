{
  config,
  ...
}: let
  wallpaper = config.stylix.image;
in {
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = true;
      splash_offset = 2.0;

      preload = [wallpaper];

      wallpaper = [",${wallpaper}"];
    };
  };
}
