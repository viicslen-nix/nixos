{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; let
  cfg = config.features.lan-mouse;
in {
  imports = [
    inputs.lan-mouse.homeManagerModules.default
  ];

  options.features.lan-mouse = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable lan-mouse";
    };
  };

  config = mkIf cfg.enable {
    programs.lan-mouse = {
      enable = true;
      systemd = true;
    };

    xdg = {
      enable = lib.mkDefault true;

      desktopEntries.lan-mouse = {
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
