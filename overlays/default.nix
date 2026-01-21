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

    # Enable vencord patch for official discord client
    discord = _prev.discord.override {
      withVencord = true;
    };

    vscode = _prev.vscode.override {
      commandLineArgs = ''
        --enable-features=WaylandLinuxDrmSyncobj
      '';
    };

    vivaldi = _prev.vivaldi.overrideAttrs (oldAttrs: let
      version = "7.8.3925.29";
    in {
      inherit version;

      src = _prev.fetchurl {
        url = "https://downloads.vivaldi.com/snapshot/vivaldi-snapshot_${version}-1_amd64.deb";
        hash = "sha256-OOH1fQW/sVXvMcHeayAMcvgQIbmdYNPHpBVb/xPbLdI=";
      };

      passthru = (oldAttrs.passthru or {}) // {
        isSnapshot = true;
      };

      buildPhase =
        builtins.replaceStrings
        ["opt/vivaldi/"]
        ["opt/vivaldi-snapshot/"]
        oldAttrs.buildPhase;

      installPhase =
        builtins.replaceStrings
        ["opt/vivaldi/vivaldi" "vivaldi-stable" "opt/vivaldi/product" "opt/vivaldi/WidevineCdm" "opt/vivaldi/resources"]
        ["opt/vivaldi-snapshot/vivaldi-snapshot" "vivaldi-snapshot" "opt/vivaldi-snapshot/product" "opt/vivaldi-snapshot/WidevineCdm" "opt/vivaldi-snapshot/resources"]
        oldAttrs.installPhase;
    });

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
