{
  lib,
  pkgs,
  config,
  options,
  ...
}:
with lib; let
  name = "ray";
  namespace = "programs";

  cfg = config.${namespace}.${name};
  appImage = pkgs.appimageTools.wrapType2 {
    inherit name;
    src = pkgs.fetchurl {
      url = "https://ray-app.s3.eu-west-1.amazonaws.com/Ray-2.7.5.AppImage";
      hash = "sha256-DgAzfbFO9XpCjZkeGmBU6B9G8XiVwfTjoHioWL7seX8=";
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
        name = "Ray";
        genericName = "Debugging Tool";
        exec = "${appImage}/bin/${name} %U";
        icon = name;
        terminal = false;
        comment = "Ray is a tool for debugging and profiling your PHP applications.";
        categories = ["Development"];
        settings = {
          StartupWMClass = name;
        };
      };
    };
  };
}
