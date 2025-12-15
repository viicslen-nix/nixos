# This file defines overlays
{inputs, ...}: {
  # For every flake input, aliases 'pkgs.inputs.${flake}' to
  # 'inputs.${flake}.packages.${pkgs.system}' or
  # 'inputs.${flake}.legacyPackages.${pkgs.system}'
  flake-inputs = final: _: {
    inputs =
      builtins.mapAttrs (
        _: flake: let
          legacyPackages = (flake.legacyPackages or {}).${final.system} or {};
          packages = (flake.packages or {}).${final.system} or {};
        in
          if legacyPackages != {}
          then legacyPackages
          else packages
      )
      inputs;
  };

  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: {
    local = inputs.self.packages.${final.system};
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  # When applied, the stable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.stable'
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: _prev: {
    # Make Microsoft-Edge not be shit on Wayland
    microsoft-edge-wayland = _prev.symlinkJoin {
      name = "microsoft-edge-wayland";
      paths = [_prev.microsoft-edge];
      buildInputs = [_prev.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/microsoft-edge \
        --add-flags "--ozone-platform=wayland" \
        --add-flags "--enable-features=UseOzonePlatform" \
        --add-flags "--enable-features=WaylandLinuxDrmSyncobj"
      '';
    };

    # Vivaldi with custom JS UI mods support
    # Based on https://github.com/budlabs/vivaldi-autoinject-custom-js-ui
    # Usage: pkgs.vivaldi.override { customJsFiles = [ ./my-mod.js ]; }
    vivaldi = _prev.callPackage ({
      vivaldi,
      customJsFiles ? [],
      enableWayland ? true,
      symlinkJoin,
      makeWrapper,
      writeTextFile,
      runCommand,
      lib,
    }: let
      # Create a patched Vivaldi with custom JS files injected
      patchedVivaldi = runCommand "vivaldi-custom-ui-${vivaldi.version}" {
        inherit (vivaldi) meta;
        nativeBuildInputs = [makeWrapper];
      } ''
        # Create output directory structure
        mkdir -p $out

        # Copy the original Vivaldi, preserving symlinks
        cp -rs ${vivaldi}/* $out/

        # Make the resources/vivaldi directory writable
        chmod -R u+w $out

        # Remove the symlink to window.html and copy the actual file
        rm -f $out/share/vivaldi/resources/vivaldi/window.html
        cp ${vivaldi}/share/vivaldi/resources/vivaldi/window.html \
           $out/share/vivaldi/resources/vivaldi/window.html
        chmod u+w $out/share/vivaldi/resources/vivaldi/window.html

        # Copy custom JS files to Vivaldi resources directory
        ${lib.concatMapStringsSep "\n" (jsFile: ''
          cp ${jsFile} $out/share/vivaldi/resources/vivaldi/${builtins.baseNameOf (toString jsFile)}
        '') customJsFiles}

        # Inject script tags into window.html before </body>
        ${lib.concatMapStringsSep "\n" (jsFile: let
          fileName = builtins.baseNameOf (toString jsFile);
        in ''
          if ! grep -q '<script src="${fileName}"></script>' $out/share/vivaldi/resources/vivaldi/window.html; then
            sed -i 's|</body>|  <script src="${fileName}"></script>\n</body>|' \
              $out/share/vivaldi/resources/vivaldi/window.html
          fi
        '') customJsFiles}

        # Re-wrap the Vivaldi binary
        rm -f $out/bin/vivaldi
        makeWrapper ${vivaldi}/bin/vivaldi $out/bin/vivaldi \
          ${lib.optionalString enableWayland ''
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=UseOzonePlatform"
          ''}
      '';
    in
      patchedVivaldi
    ) {};

    # Enable vencord patch for official discord client
    discord = _prev.discord.override {
      withVencord = true;
    };

    vscode = _prev.vscode.override {
      commandLineArgs = ''
        --enable-features=WaylandLinuxDrmSyncobj
      '';
    };

    # Patch openssh to ignore file permissions on ssh_config file
    # openssh = _prev.openssh.overrideAttrs (old: {
    #   patches = (old.patches or [ ]) ++ [ ./openssh.patch ];
    #   doCheck = false;
    # });

    # _1password-gui-wayland = _prev._1password-gui.overrideAttrs (oldAttrs: {
    #   preFixup = ''
    #     # makeWrapper defaults to makeBinaryWrapper due to wrapGAppsHook
    #     # but we need a shell wrapper specifically for `NIXOS_OZONE_WL`.
    #     # Electron is trying to open udev via dlopen()
    #     # and for some reason that doesn't seem to be impacted from the rpath.
    #     # Adding udev to LD_LIBRARY_PATH fixes that.
    #     # Make xdg-open overrideable at runtime.
    #     makeShellWrapper $out/share/1password/1password $out/bin/1password \
    #       "''${gappsWrapperArgs[@]}" \
    #       --suffix PATH : ${_prev.lib.makeBinPath [_prev.xdg-utils]} \
    #       --prefix LD_LIBRARY_PATH : ${_prev.lib.makeLibraryPath [_prev.udev]} \
    #       --add-flags "--ozone-platform=wayland" \
    #       --add-flags "--enable-wayland-ime=true" \
    #       --add-flags "--ozone-platform-hint=auto" \
    #       --add-flags "--enable-features=UseOzonePlatform" \
    #       --add-flags "--enable-features=WaylandWindowDecorations" \
    #       --add-flags "--enable-features=WaylandLinuxDrmSyncobj" \
    #       --add-flags "--disable-gpu-sandbox"
    #   '';
    # });
  };
}
