{
  flake.modules.homeManager.vivaldi = {
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
        resources = "$out/${basePath}/resources/vivaldi";
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
          rm -f ${resources}/window.html
          cp ${vivaldiPackage}/${basePath}/resources/vivaldi/window.html ${resources}/window.html
          chmod u+w ${resources}/window.html

          ${optionalString cfg.enableMods ''
            # Awesome-Vivaldi's layout: the loader sits at the resources root and
            # discovers everything under user_mods/ at runtime, so one script tag
            # covers every mod (see the modpack's install.sh).
            cp ${cfg.modsPackage}/injectMods.js ${resources}/injectMods.js
            cp -r ${cfg.modsPackage}/user_mods ${resources}/user_mods
            chmod -R u+w ${resources}/user_mods

            sed -i 's|</body>|  <script src="injectMods.js"></script>\n</body>|' \
              ${resources}/window.html
          ''}

          # Re-wrap the Vivaldi binary with Wayland flags if enabled
          rm -rf $out/bin
          mkdir -p $out/bin
          makeWrapper ${vivaldiPackage}/bin/${binaryName} $out/bin/${binaryName} \
            --add-flags "--user-data-dir=\$HOME/${cfg.profileDir}" \
            ${optionalString cfg.enableWayland ''
            --add-flags "--ozone-platform=wayland" \
            --add-flags "--enable-features=UseOzonePlatform"
          ''}
        '';
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc "Vivaldi browser with custom mods");

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

        profileDir = mkOption {
          type = types.str;
          default = ".config/vivaldi";
          description = ''
            Profile directory, relative to $HOME. Pinning it keeps one profile
            across channels — a snapshot build would otherwise default to
            ~/.config/vivaldi-snapshot. Only one Vivaldi can hold it at a time.
          '';
        };

        enableMods = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Install the mod pack into Vivaldi's resources and load it from
            window.html. When disabled, vanilla Vivaldi is used.
          '';
        };

        modsPackage = mkOption {
          type = types.package;
          default = pkgs.inputs.packages.awesome-vivaldi;
          description = ''
            Mod pack to install. Must provide `injectMods.js` and a `user_mods`
            directory laid out as https://github.com/PaRr0tBoY/Awesome-Vivaldi
            deploys them; mods are configured in-browser through its ModConfig.
          '';
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          home.packages = [vivaldiWithMods];

          programs.chromium = {
            enable = true;
            package = vivaldiWithMods;
            extensions = [
              {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";}
              {id = "edibdbjcniadpccecjdfdjjppcpchdlm";}
              {id = "gfbliohnnapiefjpjlpjnehglfpaknnc";}
            ];
          };
        }

        # Persistence support
        (persistence.mkPersistence config {
          config = ["vivaldi"];
          cache = ["vivaldi"];
        })
      ]);
    };
}
