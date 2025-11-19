{
  lib,
  stdenv,
  buildFHSEnv,
  makeWrapper,
  alsa-lib,
  at-spi2-core,
  cups,
  dbus,
  glib,
  gtk3,
  libdrm,
  libnotify,
  libsecret,
  libuuid,
  libX11,
  libXScrnSaver,
  libXcomposite,
  libXcursor,
  libXdamage,
  libXext,
  libXfixes,
  libXi,
  libXrandr,
  libXrender,
  libXtst,
  mesa,
  nspr,
  nss,
  wayland,
  xkbcomp,
  xorg,
  zlib,
  callPackage,
  ...
}: let
  raw = callPackage ./default.nix {};

  fhs = buildFHSEnv {
    name = "antigravity-fhs";
    targetPkgs = pkgs:
      with pkgs; [
        raw
        alsa-lib
        at-spi2-core
        cups
        dbus
        glib
        gtk3
        libdrm
        libnotify
        libsecret
        libuuid
        libX11
        libXScrnSaver
        libXcomposite
        libXcursor
        libXdamage
        libXext
        libXfixes
        libXi
        libXrandr
        libXrender
        libXtst
        mesa
        nspr
        nss
        wayland
        xkbcomp
        xorg.libxcb
        xorg.libxkbfile
        zlib
      ];
    runScript = "${raw}/bin/antigravity";
  };
in
  stdenv.mkDerivation {
    pname = raw.pname;
    inherit (raw) version;
    nativeBuildInputs = [makeWrapper];
    buildInputs = [raw fhs];
    phases = ["installPhase"];
    installPhase = ''
      mkdir -p $out/bin
      # Wrapper from FHS env is symlinked as main binary
      ln -s ${fhs}/bin/antigravity $out/bin/antigravity

      # Copy desktop file from raw derivation
      mkdir -p $out/share/applications
      cp ${raw}/share/applications/antigravity.desktop $out/share/applications/

      # Copy icon from raw derivation
      mkdir -p $out/share/icons/hicolor/128x128/apps
      cp ${raw}/share/icons/hicolor/128x128/apps/antigravity.png $out/share/icons/hicolor/128x128/apps/
    '';
    meta = raw.meta // {description = raw.meta.description + " (FHS wrapped)";};
    passthru = {
      inherit raw fhs;
      desktopItem = raw.passthru.desktopItem;
    };
  }
