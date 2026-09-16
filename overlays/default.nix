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

  # Must be applied *after* `flake-inputs`, which is what creates `pkgs.inputs`.
  superset-fork = _final: prev: let
    # The fork's `superset-desktop` attr, not `superset` — the CLI installs `bin/superset` too.
    fork = inputs.superset-desktop.packages.${prev.stdenv.hostPlatform.system}.superset-desktop;
  in {
    inputs =
      prev.inputs
      // {
        packages =
          prev.inputs.packages
          // {
            superset = prev.inputs.packages.superset // {desktop = fork;};
          };
      };
  };

  # llm-agents' t3code trails upstream; this bumps it in place. To move it, set
  # `version`, then take each hash from the build that rejects the stale one.
  # Must be applied *after* `flake-inputs`, which is what creates `pkgs.inputs`.
  t3code-version = _final: prev: let
    inherit (prev.lib) concatStrings mapAttrsToList replaceStrings;

    version = "0.0.42";

    # 0.0.42 wants Electron 44, which only llm-agents' own nixpkgs carries.
    electron = inputs.llm-agents.inputs.nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}.electron_44;

    src = prev.fetchFromGitHub {
      owner = "pingdotgg";
      repo = "t3code";
      tag = "v${version}";
      hash = "sha256-YV86WqqpGQwjeovXB0IoE3f/o4IUC5DDVdBEdT4xzjc=";
    };

    # The web build downloads these license texts unless they are already
    # cached; the sandbox has no network, so seed the cache. Both paths are
    # pinned in `scripts/lib/third-party-licenses.ts` — re-read it on a bump.
    spdxRev = "c4a7237ec8f4654e867546f9f409749300f1bf4c";
    spdxCache = ".generated/third-party-licenses/spdx/v3.28.0";
    spdxLicenses = {
      "Apache-2.0" = "sha256-iyt7wmfXAL6UCFzSyDA+Atj4ODKLKnMQ3DqIQNPKErs=";
      "BSD-2-Clause" = "sha256-h2hDpwacR4mNECQyo1vjMqRXz3r/gJTMsYqj315jQJI=";
      "BSD-3-Clause" = "sha256-RXYFS3RBfUAh/9ovY7h/3lJ5Hj7ZTu7yznkwJRtDcwE=";
      "CC0-1.0" = "sha256-gdRg6RFSHhS1Ky/Y4Gl5Wscx6JhspYpdKUFdzAHqoSU=";
      "ISC" = "sha256-VJTDV7IdtsBt1r1r1J1ldZINPVNDQE5vVFkWPmjn5Yo=";
      "MIT" = "sha256-fuCJ3MxiW/GLCrHoDgxLysVYeIT1viXZATuK1sYd1Dk=";
      "Unlicense" = "sha256-itR5uQEH/xGJKbe09Fvk/axB/Aq0J6LEIbwwY52X4fs=";
    };

    seedSpdxCache =
      ''
        mkdir -p ${spdxCache}
      ''
      + concatStrings (mapAttrsToList (id: hash: ''
          cp ${prev.fetchurl {
            url = "https://raw.githubusercontent.com/spdx/license-list-data/${spdxRev}/json/details/${id}.json";
            inherit hash;
          }} ${spdxCache}/${id}.json
        '')
        spdxLicenses);

    base = prev.inputs.llm-agents.t3code;

    unwrapped = (base.unwrapped.override {electron_43 = electron;}).overrideAttrs (old: let
      resourceMonitor = old.passthru.resourceMonitor.overrideAttrs (o: {
        inherit version src;
        cargoDeps = o.cargoDeps.overrideAttrs {
          inherit src;
          outputHash = "sha256-tQAQZ/ZPnJytCyCKymGU8yoQrbYuI7aVXPZ7RS5wvaw=";
          # overrideAttrs resets the hash mode to flat; a vendor dir needs recursive.
          outputHashMode = "recursive";
        };
      });
    in {
      inherit version src;

      pnpmDeps = old.pnpmDeps.overrideAttrs {
        inherit src version;
        outputHash = "sha256-gEY2em9pNTC1EuVX0V3L/Wu1apZ+BKBXxALEcPQ/pwA=";
      };

      postPatch = (old.postPatch or "") + seedSpdxCache;

      # Both phases carry the old version and resource-monitor path as literals.
      preBuild = replaceStrings [old.version] [version] old.preBuild;
      installPhase =
        replaceStrings
        ["${old.passthru.resourceMonitor}"]
        ["${resourceMonitor}"]
        old.installPhase;

      passthru = old.passthru // {inherit resourceMonitor;};
    });
  in {
    inputs =
      prev.inputs
      // {
        llm-agents =
          prev.inputs.llm-agents
          // {
            t3code = base.override {t3code-unwrapped = unwrapped;};
          };
      };
  };

  modifications = final: _prev: {
    # Keep until niri-flake moves to libdisplay-info_0_3 — pkgs.niri-unstable needs 0.2.
    libdisplay-info_0_2 = _prev.libdisplay-info_0_3.overrideAttrs (_: {
      version = "0.2.0";
      src = _prev.fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "emersion";
        repo = "libdisplay-info";
        tag = "0.2.0";
        hash = "sha256-6xmWBrPHghjok43eIDGeshpUEQTuwWLXNHg7CnBUt3Q=";
      };
    });

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
