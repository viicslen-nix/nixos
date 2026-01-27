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

  # Local mods directory
  modsDir = ./mods;

  # List of JavaScript mods to include
  defaultJsMods = [
    "tidy-titles.js"
    "tidy-tabs.js"
    "clear-tabs.js"
    "wrap-today.js"
    "immersive-addressbar.js"
    "tab-scroll.js"
    "yb-address-bar.js"
    "element-capture.js"
    "global-media-controls.js"
    "auto-hide-panel.js"
    "easy-files.js"
    "dialog-tab.js"
    "moon-phase.js"
    "monochrome-icons.js"
  ];

  # Map mod names to their paths in the local mods directory
  getModPath = modName: let
    modPaths = {
      # Root level mods
      "tidy-titles.js" = "js/tidy-titles.js";
      "tidy-tabs.js" = "js/tidy-tabs.js";
      "clear-tabs.js" = "js/clear-tabs.js";
      "wrap-today.js" = "js/wrap-today.js";
      "immersive-addressbar.js" = "js/immersive-addressbar.js";
      "mainbar.js" = "js/mainbar.js";

      # aminought mods
      "yb-address-bar.js" = "js/aminought/yb-address-bar.js";
      "color-tabs.js" = "js/aminought/color-tabs.js";

      # tam710562 mods
      "element-capture.js" = "js/tam710562/element-capture.js";
      "global-media-controls.js" = "js/tam710562/global-media-controls.js";
      "easy-files.js" = "js/tam710562/easy-files.js";
      "dialog-tab.js" = "js/tam710562/dialog-tab.js";
      "md-notes.js" = "js/tam710562/md-notes.js";
      "import-export-command-chains.js" = "js/tam710562/import-export-command-chains.js";
      "feed-icon.js" = "js/tam710562/feed-icon.js";
      "adaptive-web-panel-headers.js" = "js/tam710562/adaptive-web-panel-headers.js";
      "click-add-block-list.js" = "js/tam710562/click-add-block-list.js";
      "select-search.js" = "js/tam710562/select-search.js";

      # luetage mods
      "tab-scroll.js" = "js/luetage/tab-scroll.js";
      "moon-phase.js" = "js/luetage/moon-phase.js";
      "monochrome-icons.js" = "js/luetage/monochrome-icons.js";
      "accent-mod.js" = "js/luetage/accent-mod.js";
      "collapse-keyboard-settings.js" = "js/luetage/collapse-keyboard-settings.js";
      "backup-search-engines.js" = "js/luetage/backup-search-engines.js";
      "activate-tab-on-hover.js" = "js/luetage/activate-tab-on-hover.js";
      "theme-internal.js" = "js/luetage/theme-internal.js";

      # other mods
      "auto-hide-panel.js" = "js/other/auto-hide-panel.js";
      "g-bartsch-hibernate-tabs.js" = "js/other/g-bartsch-hibernate-tabs.js";
      "picture-in-picture.js" = "js/other/picture-in-picture.js";
      "vivaldi-dashboard-camo.js" = "js/other/vivaldi-dashboard-camo.js";

      # page-action mods
      "follower-tabs.js" = "js/page-action/follower-tabs.js";
      "tabs-lock.js" = "js/page-action/tabs-lock.js";
    };
  in
    modPaths.${modName} or "js/${modName}";

  # Build custom JS files from local mods
  customJsFiles =
    if cfg.enableMods
    then map (modName: "${modsDir}/${getModPath modName}") cfg.jsMods
    else [];

  vivaldiPackage = cfg.package.override {
    proprietaryCodecs = true;
    enableWidevine = true;
  };

  # Detect if this is a snapshot version and set the correct base path
  isSnapshot = vivaldiPackage.isSnapshot or false;
  vivaldiBasePath =
    if isSnapshot
    then "opt/vivaldi-snapshot"
    else "opt/vivaldi";
  vivaldiBinaryName = "vivaldi"; # Binary is always named 'vivaldi' regardless of snapshot/stable
  # Based on https://github.com/budlabs/vivaldi-autoinject-custom-js-ui
  vivaldiWithMods = let
    basePath = vivaldiBasePath;
    binaryName = vivaldiBinaryName;
  in
    pkgs.runCommand "vivaldi-custom-ui-${vivaldiPackage.version}" {
      nativeBuildInputs = [pkgs.makeWrapper];
      # Lower priority number = higher precedence (resolves buildEnv conflicts)
      meta = (vivaldiPackage.meta or {}) // {priority = 4;};
    } ''
      # Create output directory structure
      mkdir -p $out

      # Copy the original Vivaldi, preserving symlinks
      cp -rs ${vivaldiPackage}/* $out/

      # Make the resources/vivaldi directory writable
      chmod -R u+w $out

      # Remove the symlink to window.html and copy the actual file
      rm -f $out/${basePath}/resources/vivaldi/window.html
      cp ${vivaldiPackage}/${basePath}/resources/vivaldi/window.html \
         $out/${basePath}/resources/vivaldi/window.html
      chmod u+w $out/${basePath}/resources/vivaldi/window.html

      # Copy custom JS files to Vivaldi resources directory
      ${lib.concatMapStringsSep "\n" (jsFile: ''
          cp ${jsFile} $out/${basePath}/resources/vivaldi/${builtins.baseNameOf (toString jsFile)}
        '')
        customJsFiles}

      # Inject script tags into window.html before </body>
      ${lib.concatMapStringsSep "\n" (jsFile: let
          fileName = builtins.baseNameOf (toString jsFile);
        in ''
          if ! grep -q '<script src="${fileName}"></script>' $out/${basePath}/resources/vivaldi/window.html; then
            sed -i 's|</body>|  <script src="${fileName}"></script>\n</body>|' \
              $out/${basePath}/resources/vivaldi/window.html
          fi
        '')
        customJsFiles}

      # Re-wrap the Vivaldi binary with Wayland flags if enabled
      rm -rf $out/bin
      mkdir -p $out/bin
      makeWrapper ${vivaldiPackage}/bin/${binaryName} $out/bin/${binaryName} \
        ${lib.optionalString cfg.enableWayland ''
        --add-flags "--ozone-platform=wayland" \
        --add-flags "--enable-features=UseOzonePlatform"
      ''}
    '';
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "Vivaldi browser with custom mods");

    package = mkOption {
      type = types.package;
      default = pkgs.vivaldi;
      description = ''
        The Vivaldi package to use as the base.
        This package will be overridden with proprietaryCodecs and enableWidevine.
      '';
    };

    enableWayland = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Wayland-specific flags for Vivaldi";
    };

    enableMods = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable all mods for Vivaldi.
        When disabled, all JS and CSS mods are disabled and vanilla Vivaldi is used.
      '';
    };

    jsMods = mkOption {
      type = types.listOf types.str;
      default = defaultJsMods;
      description = ''
        List of JavaScript mods to enable from the local mods directory.
        Available mods:
        - tidy-titles.js - AI-powered tab title optimization
        - tidy-tabs.js - AI-powered tab organization
        - clear-tabs.js - Clear/close tabs functionality
        - wrap-today.js - Wrap today's date
        - immersive-addressbar.js - Immersive address bar
        - mainbar.js - Main bar modifications
        - tab-scroll.js - Tab scrolling functionality
        - yb-address-bar.js - Enhanced address bar
        - element-capture.js - Element capture functionality
        - global-media-controls.js - Global media controls panel
        - auto-hide-panel.js - Auto-hide panel
        - easy-files.js - Easy file attachments
        - dialog-tab.js - Dialog tab functionality
        - moon-phase.js - Moon phase display
        - monochrome-icons.js - Monochrome icons
        - accent-mod.js - Accent color modifications
        - md-notes.js - Markdown notes editor
        - import-export-command-chains.js - Import/export command chains
        - feed-icon.js - RSS feed icon
        - adaptive-web-panel-headers.js - Adaptive web panel headers
        - click-add-block-list.js - Click to add to block list
        - collapse-keyboard-settings.js - Collapse keyboard settings
        - backup-search-engines.js - Backup search engines
        - activate-tab-on-hover.js - Activate tab on hover
        - color-tabs.js - Color tabs
        - theme-internal.js - Theme internal
        - g-bartsch-hibernate-tabs.js - Hibernate tabs
        - picture-in-picture.js - Picture in picture
        - vivaldi-dashboard-camo.js - Dashboard camo
        - follower-tabs.js - Follower tabs
        - tabs-lock.js - Tabs lock
        - select-search.js - Select search
      '';
    };

    enableCssMods = mkOption {
      type = types.bool;
      default = true;
      description = "Enable CSS mods from local mods directory (requires enabling CSS mods in Vivaldi settings)";
    };

    cssModsPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Custom path for CSS mods. If null, uses the local CSS directory.
        Note: You need to manually set this path in Vivaldi settings under
        Appearance > Custom UI Modifications.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [vivaldiWithMods];

      # Symlink CSS mods to a predictable location
      home.file = mkIf (cfg.enableCssMods && cfg.enableMods) {
        ".config/vivaldi/custom-css" = {
          source =
            if cfg.cssModsPath != null
            then cfg.cssModsPath
            else "${modsDir}/css";
          recursive = true;
        };
      };
    }

    # Persistence support
    (mkPersistence config {
      config = ["vivaldi"];
      cache = ["vivaldi"];
    })
  ]);
}
