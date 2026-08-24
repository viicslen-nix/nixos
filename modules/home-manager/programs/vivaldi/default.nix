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

      extraCssMods = filter (hasSuffix ".css") (attrNames cfg.extraMods);

      # The mods have to live *inside* the package: Vivaldi's launcher resolves
      # its own directory through `readlink -f "$0"`, and Chromium finds
      # resources/ next to the real binary, so a patched copy wrapped around the
      # original store path is simply never read.
      # Based on https://github.com/budlabs/vivaldi-autoinject-custom-js-ui
      moddedPackage =
        if !cfg.enableMods
        then vivaldiPackage
        else
          vivaldiPackage.overrideAttrs (oldAttrs: {
            # Awesome-Vivaldi's layout: the loader sits at the resources root and
            # discovers everything under user_mods/ at runtime, so one script tag
            # covers every mod (see the modpack's install.sh).
            postFixup =
              (oldAttrs.postFixup or "")
              + ''
                resources="$out/${vivaldiBasePath}/resources/vivaldi"

                cp ${cfg.modsPackage}/injectMods.js "$resources/injectMods.js"
                cp -r ${cfg.modsPackage}/user_mods "$resources/user_mods"
                chmod -R u+w "$resources/user_mods"

                chmod u+w "$resources/window.html"
                sed -i 's|</body>|  <script src="injectMods.js"></script>\n</body>|' \
                  "$resources/window.html"

                # A name that no longer exists upstream would otherwise drop out
                # silently — as an omission it looks exactly like a working build.
                assertMods() {
                  local dir="$1"; shift
                  for mod in "$@"; do
                    [ -e "$dir/$mod" ] || {
                      echo "vivaldi: no such mod '$mod' in ${cfg.modsPackage} ($dir)" >&2
                      exit 1
                    }
                  done
                }

                ${optionalString (cfg.jsMods != null) ''
                  # The loader lists user_mods/js at runtime, so the selection is
                  # simply which files are there.
                  assertMods "$resources/user_mods/js" ${escapeShellArgs cfg.jsMods}
                  keep=" ${concatStringsSep " " cfg.jsMods} "
                  for js in "$resources"/user_mods/js/*.js; do
                    case "$keep" in
                      *" $(basename "$js") "*) ;;
                      *) rm "$js" ;;
                    esac
                  done
                ''}

                ${optionalString (cfg.cssMods != null) ''
                  # CSS is pulled in by Import.css alone, so the selection is that
                  # file — upstream's own copy leaves several mods commented out.
                  assertMods "$resources/user_mods/css" ${escapeShellArgs cfg.cssMods}
                  printf '@import "%s";\n' ${escapeShellArgs cfg.cssMods} \
                    >"$resources/user_mods/css/Import.css"
                ''}

                ${concatStringsSep "\n" (mapAttrsToList (
                    fileName: source: ''
                      cp ${source} "$resources/user_mods/${
                        if hasSuffix ".css" fileName
                        then "css"
                        else "js"
                      }/${fileName}"
                    ''
                  )
                  cfg.extraMods)}

                ${optionalString (extraCssMods != []) ''
                  # Appended last: Import.css is the only stylesheet the loader
                  # reads, and later @imports win the cascade.
                  printf '@import "%s";\n' ${escapeShellArgs extraCssMods} \
                    >>"$resources/user_mods/css/Import.css"
                ''}
              '';
          });

      vivaldiWithMods = let
        binaryName = vivaldiBinaryName;
      in
        pkgs.runCommand "vivaldi-custom-ui-${moddedPackage.version}" {
          nativeBuildInputs = [pkgs.makeWrapper];
          # Lower priority number = higher precedence (resolves buildEnv conflicts)
          meta = (moddedPackage.meta or {}) // {priority = 4;};
        } ''
          mkdir -p $out/bin
          makeWrapper ${moddedPackage}/bin/${binaryName} $out/bin/${binaryName} \
            --add-flags "--user-data-dir=\$HOME/${cfg.profileDir}" \
            ${optionalString cfg.enableWayland ''
            --add-flags "--ozone-platform=wayland" \
            --add-flags "--enable-features=UseOzonePlatform"
          ''}

          # Desktop entries point Exec= at the package's own bin/vivaldi, which
          # would skip the flags above; copy them out of the symlink farm and
          # aim them here instead.
          cp -rs ${moddedPackage}/share $out/share
          find $out/share -type d -exec chmod u+w {} +
          for desktop in $out/share/applications/*.desktop; do
            cp --remove-destination "$(readlink -f "$desktop")" "$desktop"
            chmod u+w "$desktop"
            substituteInPlace "$desktop" \
              --replace-fail "${moddedPackage}/bin/${binaryName}" "$out/bin/${binaryName}"
          done
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

        jsMods = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          example = ["ModConfig.js" "TidyTabs.js" "VividToast.js"];
          description = ''
            JS mods to install, named as the files under `user_mods/js` in the
            pack (`nix build .#awesome-vivaldi` to list them). `null` installs
            everything it ships. ModConfig.js carries the in-browser settings for
            the rest, and unknown names fail the build.
          '';
        };

        cssMods = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          example = ["VividToast.css" "TidyTabs.css"];
          description = ''
            CSS mods to enable, named as the files under `user_mods/css` in the
            pack. `null` keeps its own Import.css, which already leaves several
            of them commented out. A list rewrites Import.css instead; unknown
            names fail the build.
          '';
        };

        extraMods = mkOption {
          type = types.attrsOf types.path;
          default = {};
          example = literalExpression ''
            {
              "FluidTabbar.css" = pkgs.fetchurl {
                url = "https://raw.githubusercontent.com/…/autoHideTab.css";
                hash = "sha256-…";
              };
            }
          '';
          description = ''
            Mods from outside the pack, keyed by file name. The extension picks
            the destination: `.js` lands in `user_mods/js` for the loader to pick
            up, `.css` in `user_mods/css` and appended to Import.css last, so it
            wins the cascade.
          '';
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          # A name the dispatch can't place would land in user_mods/js and be
          # loaded as a script.
          assertions =
            mapAttrsToList (fileName: _: {
              assertion = hasSuffix ".js" fileName || hasSuffix ".css" fileName;
              message = "modules.${namespace}.${name}.extraMods: '${fileName}' must end in .js or .css";
            })
            cfg.extraMods;

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
