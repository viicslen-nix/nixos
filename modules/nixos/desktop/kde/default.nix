{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
with lib; let
  name = "kde";
  namespace = "desktop";

  cfg = config.modules.${namespace}.${name};
  homeManagerLoaded = builtins.hasAttr "home-manager" options;
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc feature);

    enableSddm = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable the SDDM window manager";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.xserver.enable = mkDefault true;
      services.desktopManager.plasma6.enable = true;

      services.displayManager.sddm = mkIf cfg.enableSddm {
        enable = true;
        wayland.enable = true;
      };

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        konsole
        oxygen
      ];
    }
    (mkIf homeManagerLoaded {
      home-manager.sharedModules = [
        inputs.plasma-manager.homeManagerModules.plasma-manager
        ./home.nix
      ];
    })
  ]);
}
