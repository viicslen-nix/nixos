# This file defines overlays
{inputs, ...}: let
  inherit (inputs.viicslen-lib.lib.overlays) mkFlakeInputsOverlay mkChannelOverlay;
in {
  flake-inputs = mkFlakeInputsOverlay inputs;

  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: {
    local = inputs.self.packages.${final.stdenv.hostPlatform.system};
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = mkChannelOverlay {
    attr = "unstable";
    flake = inputs.nixpkgs-unstable;
    config = {
      allowUnfree = true;
      permittedInsecurePackages = ["openssl-1.1.1w"];
    };
  };

  # When applied, the stable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.stable'
  stable-packages = mkChannelOverlay {
    attr = "stable";
    flake = inputs.nixpkgs-stable;
  };

  modifications = final: _prev: {
    # Skips a doctest that fails on python 3.14; without it nix-alien won't build.
    pythonPackagesExtensions =
      (_prev.pythonPackagesExtensions or [])
      ++ [
        (_pyfinal: pyprev: {
          dpcontracts = pyprev.dpcontracts.overridePythonAttrs (_: {
            dontUsePytestCheck = true;
            doCheck = false;
            doInstallCheck = false;
          });
        })
      ];

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

    # Snapshot channel + version bump; defined in the `packages` subflake.
    vivaldi = final.local.vivaldi-snapshot;

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
