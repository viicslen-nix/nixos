{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; let
  name = "lan-mouse";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  imports = [
    inputs.lan-mouse.homeManagerModules.default
  ];

  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
    autostart = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Automatically start the Lan Mouse program when the graphical session starts.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.lan-mouse = {
      enable = true;
      systemd = true;
    };

    systemd.user.services.lan-mouse = mkIf cfg.autostart {
      Unit = {
        After = "graphical-session.target";
        BindsTo = "graphical-session.target";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    xdg = mkIf cfg.autostart {
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
