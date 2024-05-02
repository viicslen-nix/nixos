{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; let
  name = "lan-mouse";
  namespace = "features";

  cfg = config.${namespace}.${name};
in {
  imports = [
    inputs.lan-mouse.homeManagerModules.default
  ];

  options.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    programs.lan-mouse = {
      enable = true;
      systemd = true;
    };

    xdg = {
      enable = lib.mkDefault true;

      desktopEntries.${name} = {
        name = "Lan Mouse";
        genericName = "KVM";
        exec = "${inputs.lan-mouse.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/lan-mouse %U";
        icon = "lan-mouse";
        terminal = false;
        settings = {
          StartupWMClass = "lan-mouse";
        };
      };
    };
  };
}
