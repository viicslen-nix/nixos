{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  buildFHSEnv,
  makeWrapper,
  makeDesktopItem,
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
  ...
}: let
  pname = "antigravity";
  version = "1.11.3-6583016683339776";

  src = fetchurl {
    url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${version}/linux-x64/Antigravity.tar.gz";
    hash = "sha256-Al2lEvl5mnFU4sx1vAkIIBOCwazy6DePnaI1y4SlYVs=";
  };

  desktopItem = makeDesktopItem {
    name = "antigravity";
    desktopName = "Antigravity";
    genericName = "Code Editor";
    comment = "Antigravity IDE";
    exec = "antigravity %F";
    icon = "antigravity";
    categories = ["Development" "IDE"];
    mimeTypes = ["text/plain" "inode/directory"];
    terminal = false;
    startupNotify = true;
    startupWMClass = "antigravity";
  };
in
  stdenv.mkDerivation {
    pname = pname;
    inherit version src;

    nativeBuildInputs = [autoPatchelfHook makeWrapper];
    buildInputs = [
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

    unpackPhase = ''
      tar -xzf $src
    '';

    installPhase = ''
      mkdir -p $out/opt/Antigravity
      cp -r Antigravity/* $out/opt/Antigravity/
      mkdir -p $out/bin
      ln -s $out/opt/Antigravity/antigravity $out/bin/antigravity

      # Install desktop file from makeDesktopItem
      mkdir -p $out/share/applications
      cp ${desktopItem}/share/applications/antigravity.desktop $out/share/applications/

      # Install icon (using theme-seti circular icon as placeholder)
      mkdir -p $out/share/icons/hicolor/128x128/apps
      cp Antigravity/resources/app/extensions/theme-seti/icons/seti-circular-128x128.png \
        $out/share/icons/hicolor/128x128/apps/antigravity.png || true
    '';

    passthru = {
      inherit desktopItem;
    };

    meta = {
      description = "Antigravity proprietary Electron application";
      homepage = "https://antigravity.google";
      license = lib.licenses.unfreeRedistributable;
      platforms = ["x86_64-linux"];
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      mainProgram = "antigravity";
    };
  }
