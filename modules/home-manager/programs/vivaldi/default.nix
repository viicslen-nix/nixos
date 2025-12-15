{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib;
with inputs.self.lib; let
  name = "vivaldi";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};

  # Awesome-Vivaldi mod pack from GitHub
  awesomeVivaldiSrc = pkgs.fetchFromGitHub {
    owner = "PaRr0tBoY";
    repo = "Awesome-Vivaldi";
    rev = "14fccf3f2044b781383325255424541ba23de394";
    hash = "sha256-3t4XQI+NFGbpmLO5dXSn7SDvOH2dzoWpHWebeuKSYow=";
  };

  # List of JavaScript mods to include
  # Based on the recommended mods from Awesome-Vivaldi
  defaultJsMods = [
    "tidyTitles.js"
    "tidyTabs.js"
    "clearTabs.js"
    "wrapToday.js"
    "immersiveAddressbar.js"
    "tabScroll.js"
    "ybAddressBar.js"
    "elementCapture.js"
    "globalMediaControls.js"
    "autoHidePanel.js"
    "easyFiles.js"
    "dialogTab.js"
    "moonPhase.js"
    "monochromeIcons.js"
  ];

  # Map mod names to their paths in the repo
  getModPath = modName: let
    # Mods are organized in subdirectories by author
    modPaths = {
      # Root level mods
      "tidyTitles.js" = "Javascripts/tidyTitles.js";
      "tidyTabs.js" = "Javascripts/tidyTabs.js";
      "clearTabs.js" = "Javascripts/clearTabs.js";
      "wrapToday.js" = "Javascripts/wrapToday.js";
      "immersiveAddressbar.js" = "Javascripts/immersiveAddressbar.js";
      "mainbar.js" = "Javascripts/mainbar.js";

      # Tam710562 mods
      "ybAddressBar.js" = "Javascripts/aminought/ybAddressBar.js";
      "elementCapture.js" = "Javascripts/Tam710562/elementCapture.js";
      "globalMediaControls.js" = "Javascripts/Tam710562/globalMediaControls.js";
      "easyFiles.js" = "Javascripts/Tam710562/easyFiles.js";
      "dialogTab.js" = "Javascripts/Tam710562/dialogTab.js";
      "mdNotes.js" = "Javascripts/Tam710562/mdNotes.js";
      "importExportCommandChains.js" = "Javascripts/Tam710562/importExportCommandChains.js";
      "feedIcon.js" = "Javascripts/Tam710562/feedIcon.js";
      "adaptiveWebPanelHeaders.js" = "Javascripts/Tam710562/adaptiveWebPanelHeaders.js";
      "clickAddBlockList.js" = "Javascripts/Tam710562/clickAddBlockList.js";

      # Luetage mods
      "tabScroll.js" = "Javascripts/luetage/tabScroll.js";
      "moonPhase.js" = "Javascripts/luetage/moonPhase.js";
      "monochromeIcons.js" = "Javascripts/luetage/monochromeIcons.js";
      "accentMod.js" = "Javascripts/luetage/accentMod.js";
      "collapseKeyboardSettings.js" = "Javascripts/luetage/collapseKeyboardSettings.js";
      "backupSearchEngines.js" = "Javascripts/luetage/backupSearchEngines.js";
      "activateTabOnHover.js" = "Javascripts/luetage/activateTabOnHover.js";

      # Other mods
      "autoHidePanel.js" = "Javascripts/Other/autoHidePanel.js";
    };
  in
    modPaths.${modName} or "Javascripts/${modName}";

  # Build custom JS files from mod pack
  customJsFiles = map (modName: "${awesomeVivaldiSrc}/${getModPath modName}") cfg.jsMods;

  # Vivaldi with custom JS mods applied
  vivaldiWithMods = pkgs.vivaldi.override {
    inherit customJsFiles;
    enableWayland = cfg.enableWayland;
  };
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "Vivaldi browser with Awesome-Vivaldi mods");

    enableWayland = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Wayland-specific flags for Vivaldi";
    };

    jsMods = mkOption {
      type = types.listOf types.str;
      default = defaultJsMods;
      description = ''
        List of JavaScript mods to enable from the Awesome-Vivaldi mod pack.
        Available mods:
        - tidyTitles.js - AI-powered tab title optimization
        - tidyTabs.js - AI-powered tab organization
        - clearTabs.js - Clear/close tabs functionality
        - wrapToday.js - Wrap today's date
        - immersiveAddressbar.js - Immersive address bar
        - mainbar.js - Main bar modifications
        - tabScroll.js - Tab scrolling functionality
        - ybAddressBar.js - Enhanced address bar
        - elementCapture.js - Element capture functionality
        - globalMediaControls.js - Global media controls panel
        - autoHidePanel.js - Auto-hide panel
        - easyFiles.js - Easy file attachments
        - dialogTab.js - Dialog tab functionality
        - moonPhase.js - Moon phase display
        - monochromeIcons.js - Monochrome icons
        - accentMod.js - Accent color modifications
        - mdNotes.js - Markdown notes editor
        - importExportCommandChains.js - Import/export command chains
        - feedIcon.js - RSS feed icon
        - adaptiveWebPanelHeaders.js - Adaptive web panel headers
        - clickAddBlockList.js - Click to add to block list
        - collapseKeyboardSettings.js - Collapse keyboard settings
        - backupSearchEngines.js - Backup search engines
        - activateTabOnHover.js - Activate tab on hover
      '';
    };

    enableCssMods = mkOption {
      type = types.bool;
      default = true;
      description = "Enable CSS mods from Awesome-Vivaldi (requires enabling CSS mods in Vivaldi settings)";
    };

    cssModsPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Custom path for CSS mods. If null, uses the Awesome-Vivaldi CSS directory.
        Note: You need to manually set this path in Vivaldi settings under
        Appearance > Custom UI Modifications.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [vivaldiWithMods];

      # Symlink CSS mods to a predictable location
      home.file = mkIf cfg.enableCssMods {
        ".config/vivaldi/custom-css" = {
          source =
            if cfg.cssModsPath != null
            then cfg.cssModsPath
            else "${awesomeVivaldiSrc}/CSS";
          recursive = true;
        };
      };
    }

    # Persistence support
    (mkPersistence config {
      directories = [
        ".config/vivaldi"
        ".cache/vivaldi"
      ];
    })
  ]);
}
