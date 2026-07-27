{
  flake.nixosModules.ld =
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  name = "ld";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name) // {default = true;};
  };

  config = mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        gtk3
        bashInteractive
        zenity
        xrandr
        which
        perl
        xdg-utils
        iana-etc
        krb5
        gsettings-desktop-schemas
        hicolor-icon-theme # dont show a gtk warning about hicolor not being installed
        desktop-file-utils
        libxcomposite
        libxtst
        libxrandr
        libxext
        libx11
        libxfixes
        libGL

        gst_all_1.gstreamer
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-plugins-base
        libdrm
        xkeyboard-config
        libpciaccess

        glib
        bzip2
        zlib
        gdk-pixbuf

        libxinerama
        libxdamage
        libxcursor
        libxrender
        libxscrnsaver
        libxxf86vm
        libxi
        libsm
        libice
        freetype
        curlWithGnuTls
        nspr
        nss
        fontconfig
        cairo
        pango
        expat
        dbus
        cups
        libcap
        SDL2
        libusb1
        udev
        dbus-glib
        atk
        at-spi2-atk
        libudev0-shim

        libxt
        libxmu
        libxcb
        libxcb-util
        libxcb-wm
        libxcb-image
        libxcb-keysyms
        libxcb-render-util
        libGLU
        libuuid
        libogg
        libvorbis
        SDL2_image
        glew_1_10
        openssl
        libidn
        tbb
        wayland
        libgbm
        libxkbcommon
        vulkan-loader

        flac
        libglut
        libjpeg
        libpng12
        libpulseaudio
        libsamplerate
        libmikmod
        libthai
        libtheora
        libtiff
        pixman
        speex
        SDL2_ttf
        SDL2_mixer
        libcaca
        libcanberra
        libgcrypt
        libvpx
        librsvg
        libxft
        libvdpau
        alsa-lib

        harfbuzz
        e2fsprogs
        libgpg-error
        keyutils.lib
        libjack2
        fribidi
        p11-kit

        gmp

        # libraries not on the upstream include list, but nevertheless expected
        # by at least one appimage
        libtool.lib # for Synfigstudio
        at-spi2-core
        pciutils # for FreeCAD
        pipewire # immersed-vr wayland support

        libsecret # For bitwarden
        libmpg123 # Slippi launcher
        brotli # TwitchDropsMiner
      ];
    };
  };
}
  ;
}
