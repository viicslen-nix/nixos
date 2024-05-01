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

  cfg = config.${namespace}.${name};
  appImage = pkgs.appimageTools.wrapType2 {
    inherit name;
    src = pkgs.fetchurl {
      url = "https://download.tinkerwell.app/tinkerwell/Tinkerwell-4.10.0.AppImage";
      hash = "sha256-KgE/m6hpIhfVAVJ5SRtFP6RX3FwgSwej77ZQv1B2eOs=";
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
