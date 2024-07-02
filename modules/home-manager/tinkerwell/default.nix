{
  lib,
  pkgs,
  config,
  options,
  ...
}:
with lib; let
  name = "tinkerwell";
  namespace = "programs";
  version = "4.17.0";

  cfg = config.${namespace}.${name};
  appImage = pkgs.appimageTools.wrapType2 {
    inherit name;
    src = pkgs.fetchurl {
      url = "https://download.tinkerwell.app/tinkerwell/Tinkerwell-${version}.AppImage";
      hash = "";
    };
  };
in {
  options.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    home.packages = [
      appImage
    ];

    xdg = {
      enable = mkDefault true;

      desktopEntries.${name} = {
        name = "Tinkerwell";
        genericName = "IDE";
        exec = "${appImage}/bin/${name} %U";
        icon = name;
        terminal = false;
        comment = "The magical code editor that runs your code within local and remote PHP applications.";
        settings = {
          StartupWMClass = name;
        };
      };
    };
  };
}
