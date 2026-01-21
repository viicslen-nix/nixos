{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libappindicator-gtk3,
  libdbusmenu,
  libdrm,
  libnotify,
  libpulseaudio,
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
  libxcb,
  libxshmfence,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  webkitgtk_4_1,
  libsoup_3,
  xorg,
  ...
}: let
  pname = "openwork";
  version = "0.2.2";

  src = fetchurl {
    url = "https://github.com/different-ai/openwork/releases/download/v${version}/OpenWork_${version}_amd64.deb";
    hash = "sha256-Y9GRSjRR34vxNblA37GX6GaiDhwNa+qk6XKX+yeEHzY=";
  };
  runtimeLibs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libappindicator-gtk3
    libdbusmenu
    libdrm
    libnotify
    libpulseaudio
    libsoup_3
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
    libxcb
    libxshmfence
    mesa
    nspr
    nss
    pango
    systemd
    webkitgtk_4_1
    xorg.libxkbfile
  ];
in
  stdenv.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [
      autoPatchelfHook
      dpkg
      makeWrapper
    ];

    buildInputs = runtimeLibs;

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      mkdir -p $out
      cp -r usr/* $out/
      cp -r opt $out/ || true

      # Fix any broken symlinks or paths
      if [ -d $out/bin ]; then
        for file in $out/bin/*; do
          if [ -f "$file" ]; then
            wrapProgram "$file" \
              --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"
          fi
        done
      fi

      # Install desktop file if present
      if [ -d $out/share/applications ]; then
        chmod -R +w $out/share/applications
      fi
    '';

    meta = with lib; {
      description = "OpenWork - AI-powered productivity application";
      homepage = "https://github.com/different-ai/openwork";
      license = licenses.unfree;
      maintainers = [];
      platforms = ["x86_64-linux"];
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  }
