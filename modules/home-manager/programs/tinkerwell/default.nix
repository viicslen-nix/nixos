{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "tinkerwell";
  namespace = "programs";
  version = "4.19.0";

  cfg = config.modules.${namespace}.${name};
  appImage = pkgs.appimageTools.wrapType2 {
    pname = name;
    inherit version;
    src = pkgs.fetchurl {
      url = "https://download.tinkerwell.app/tinkerwell/Tinkerwell-${version}.AppImage";
      hash = "sha256-+K8YOIyK8KklZwzK9kBXXOLSvBOpBxDbwpvV8+hdSH4=";
    };
  };
in {
  options.modules.${namespace}.${name} = {
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
