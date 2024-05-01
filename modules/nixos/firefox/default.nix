{
  lib,
  pkgs,
  config,
  options,
  ...
}:
with lib; let
  feature = "firefox";
  cfg = config.features.${feature};
  homeManagerLoaded = builtins.hasAttr "home-manager" options;
in {
  options.features.${feature} = {
    enable = mkEnableOption (mdDoc feature);

    mullvadExclude = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Create Firefox desktop entry to exclude it from Mullvad VPN.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.firefox = {
        enable = true;
      };
    }
    (mkIf homeManagerLoaded (mkIf cfg.mullvadExclude {
      xdg = {
        enable = mkDefault true;

        desktopEntries.firefox-direct = {
          name = "Firefox (Direct)";
          genericName = "Web Browser";
          exec = "${pkgs.mullvad}/bin/mullvad-exclude ${pkgs.firefox}/bin/firefox";
          terminal = false;
          categories = ["Application" "Network" "WebBrowser"];
          mimeType = ["text/html" "text/xml"];
          settings = {
            StartupWMClass = "firefox";
          };
        };
      };
    }))
  ]);
}
