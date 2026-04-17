{
  lib,
  fetchurl,
  appimageTools,
  makeDesktopItem,
  copyDesktopItems,
  ...
}: let
  version = "1.18.0";
  pname = "responsively";

  src = fetchurl {
    url = "https://github.com/responsively-org/responsively-app-releases/releases/download/v${version}/ResponsivelyApp-${version}.AppImage";
    hash = "sha256-FxGlt9Ame63pwEp+6x2WLOlRVITb/QVKhr/34mKCO6c=";
  };

  appimageContents = appimageTools.extractType2 {inherit pname version src;};

  desktopItem = makeDesktopItem {
    name = pname;
    exec = pname;
    icon = pname;
    desktopName = "ResponsivelyApp";
    comment = "A browser for responsive web development";
    categories = ["Development" "WebBrowser"];
    startupWMClass = "ResponsivelyApp";
  };
in
  appimageTools.wrapType2 {
    inherit pname version src;

    nativeBuildInputs = [copyDesktopItems];

    desktopItems = [desktopItem];

    extraInstallCommands = ''
      # Install icons
      for size in 16 32 48 64 128 256 512; do
        if [ -f ${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/responsively.png ]; then
          install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/responsively.png \
            $out/share/icons/hicolor/''${size}x''${size}/apps/responsively.png
        fi
      done
    '';

    meta = {
      description = "A browser for responsive web development";
      homepage = "https://responsively.app/";
      license = lib.licenses.mit;
      mainProgram = "responsively";
      maintainers = with lib.maintainers; [];
      platforms = ["x86_64-linux"];
      sourceProvenance = with lib.sourceTypes; [lib.sourceTypes.binaryNativeCode];
    };
  }
