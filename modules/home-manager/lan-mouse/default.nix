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

    systemd.user.services.lan-mouse = {
      Unit = {
        After = "graphical-session.target";
        BindsTo = "graphical-session.target";
      };
      Install.WantedBy = ["graphical-session.target"];
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
