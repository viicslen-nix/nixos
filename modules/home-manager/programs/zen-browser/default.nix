{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib;
with inputs.self.lib; let
  name = "zen-browser";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};

  fxAutoconfig = pkgs.fetchFromGitHub {
    owner = "MrOtherGuy";
    repo = "fx-autoconfig";
    rev = "d469a80f12e286c0e937d8b93c01dfc2d55dca8f";
    hash = "sha256-czNgt62fofg3hXw7F4wXSv/+ZAsGtO6bg3sUOiUXcu4=";
  };

  secondSidebar = pkgs.fetchFromGitHub {
    owner = "k00lagin";
    repo = "zen-second-sidebar";
    rev = "2afe7fe4b745929422ac136640a340082f43ab2e";
    hash = "sha256-xsQmNfauH9zHPGVBwLIIoK5jlRPeo3I5Fg0dEdPMz04=";
  };

  zenProfileChrome = pkgs.runCommandLocal "zen-second-sidebar-profile" {} ''
    mkdir -p "$out"
    cp -r ${fxAutoconfig}/profile/chrome/. "$out/"
    chmod -R u+w "$out"
    mkdir -p "$out/JS"
    cp -r ${secondSidebar}/src/. "$out/JS/"
    mkdir -p "$out/resources"
    cp -r ${secondSidebar}/resources/. "$out/resources/"
  '';

  zenWithFxAutoconfig =
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta-unwrapped.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        for libdir in "$out"/lib/zen-bin-*; do
          chmod -R u+w "$libdir"
          cp ${fxAutoconfig}/program/config.js "$libdir/config.js"
          mkdir -p "$libdir/defaults/pref"
          cp ${fxAutoconfig}/program/defaults/pref/config-prefs.js "$libdir/defaults/pref/config-prefs.js"
        done
      '';
    });
in {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  options.modules.${namespace}.${name}.enable = mkEnableOption (mdDoc "zen-browser");

  config = mkIf cfg.enable (mkMerge [
    {
      programs.zen-browser = {
        enable = true;
        unwrappedPackage = zenWithFxAutoconfig;
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
            settings = {
              "dom.allow_scripts_to_close_windows" = true;
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            };
          };
        };
      };

      # home.file = {
      #   ".config/zen/default/chrome" = {
      #     source = zenProfileChrome;
      #     recursive = true;
      #   };
      #
      #   ".config/zen/default/search.json.mozlz4".force = mkForce true;
      # };
      xdg.configFile = {
        "zen/default/chrome" = {
          source = zenProfileChrome;
          recursive = true;
        };
      };

      home.file."${config.xdg.configHome}/zen/default/search.json.mozlz4".force = mkForce true;
    }
    (persistence.mkPersistence config {
      directories = [".config/zen"];
    })
  ]);
}
