{
  flake.modules.homeManager.thunderbird = {
    lib,
    config,
    pkgs,
    inputs,
    ...
  }:
    with lib;
    with inputs.self.lib; let
      name = "thunderbird";
      namespace = "programs";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);
        package = mkPackageOption pkgs.local "betterbird" {};

        # Anything that launches the mail client must point here, never at `package`.
        finalPackage = mkOption {
          type = types.package;
          readOnly = true;
          default = config.programs.thunderbird.finalPackage;
          defaultText = literalExpression "config.programs.thunderbird.finalPackage";
          description = mdDoc "The package actually installed, after home-manager applies policies and native messaging hosts.";
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          programs.thunderbird = {
            enable = true;
            package = cfg.package;
            profiles.default = {
              isDefault = true;
              withExternalGnupg = true;
              settings = {
                "mail.biff.show_new_alert" = true;
                "mail.spellcheck.inline" = true;
                "mailnews.default_sort_order" = 2;
                "privacy.donottrackheader.enabled" = true;
                "mail.phishing.detection.enabled" = true;
                "mail.closeToTray" = true;
                "mail.minimizeToTray" = true;
                "mail.minimizeToTray.supportedDesktops" = "kde,gnome,pop:gnome,xfce,mate,hyprland,x-cinnamon,niri";
                "mail.shell.checkDefaultClient" = false;
              };
            };
          };

          xdg.enable = mkDefault true;
        }

        (persistence.mkPersistence config {
          directories = [".thunderbird"];
        })
      ]);
    };
}
