{
  pkgs,
  homeModules,
  ...
}: {
  imports = [homeModules.programs.kitty];

  # getDesktopFileName would fall back to `showtime.desktop`.
  modules.functionality.defaults.videoPlayer = pkgs.showtime // {desktopFileName = "org.gnome.Showtime";};
}
