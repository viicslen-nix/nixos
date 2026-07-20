{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "kde";
  namespace = "desktop";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc feature);

    enableSddm = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable the SDDM window manager";
    };

    useGnomeKeyring = mkEnableOption (mdDoc "Whether to use the GNOME keyring for storing secrets");
  };

  config = mkIf cfg.enable {
    services = {
      xserver.enable = mkDefault true;
      desktopManager.plasma6.enable = true;
      gnome.gnome-keyring.enable = mkIf cfg.useGnomeKeyring true;

      displayManager.sddm = mkIf cfg.enableSddm {
        enable = true;
        wayland.enable = true;
      };
    };

    security.pam.services.login.enableGnomeKeyring = mkIf cfg.useGnomeKeyring true;

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      konsole
      oxygen
    ];

    programs.kdeconnect.enable = true;

    xdg.portal.config.kde = mkIf cfg.useGnomeKeyring {
      default = ["kde"];
      "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
    };
  };
}
