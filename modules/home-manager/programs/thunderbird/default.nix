{
  flake.modules.homeManager.thunderbird = {
    lib,
    config,
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
      };

      config = mkIf cfg.enable (mkMerge [
        {
          programs.thunderbird = {
            enable = true;
            profiles.default = {
              isDefault = true;
              withExternalGnupg = true;
              settings = {
                "mail.biff.show_new_alert" = true;
                "mail.spellcheck.inline" = true;
                "mailnews.default_sort_order" = 2;
                "privacy.donottrackheader.enabled" = true;
                "mail.phishing.detection.enabled" = true;
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
