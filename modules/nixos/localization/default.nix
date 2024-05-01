{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.features.localization;
in {
  options.features.localization = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable localization support.";
    };

    timeZone = mkOption {
      type = types.str;
      default = "America/New_York";
      description = "Set the system time zone.";
    };

    locale = mkOption {
      type = types.str;
      default = "en_US.UTF-8";
      description = "Set the system locale.";
    };
  };

  config = mkIf cfg.enable {
    # Set your time zone.
    time.timeZone = cfg.timeZone;

    # Select internationalisation properties.
    i18n = {
      defaultLocale = cfg.locale;

      extraLocaleSettings = {
        LC_ADDRESS = cfg.locale;
        LC_IDENTIFICATION = cfg.locale;
        LC_MEASUREMENT = cfg.locale;
        LC_MONETARY = cfg.locale;
        LC_NAME = cfg.locale;
        LC_NUMERIC = cfg.locale;
        LC_PAPER = cfg.locale;
        LC_TELEPHONE = cfg.locale;
        LC_TIME = cfg.locale;
      };
    };
  };
}
