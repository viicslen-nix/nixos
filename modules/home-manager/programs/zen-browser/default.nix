{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; let
  name = "zen-browser";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  options.modules.${namespace}.${name}.enable = mkEnableOption (mdDoc "zen-browser");

  config = mkIf cfg.enable {
    programs.zen-browser = {
      enable = true;
      nativeMessagingHosts = [pkgs.firefoxpwa];
      policies = {
        AutofillAddressEnabled = true;
        AutofillCreditCardEnabled = false;
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
      };
      profiles = {
        default = {
          isDefault = true;
          search.default = "google";
        };
      };
    };
  };
}
