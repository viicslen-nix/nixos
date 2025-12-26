{
  lib,
  fetchurl,
  appimageTools,
  ...
}: let
  version = "1.17.1";
  pname = "responsively";

  src = fetchurl {
    url = "https://github.com/responsively-org/responsively-app-releases/releases/download/v${version}/ResponsivelyApp-${version}.AppImage";
    hash = "sha256-GiHwWSP/iQ9AOosOor6vUoKr/ztbTfFbjytEHJjNoz4=";
  };

  appimageContents = appimageTools.extractType2 {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      # If a .desktop file or icons are present in the AppImage, install them here
      if [ -f ${appimageContents}/responsively.desktop ]; then
        install -m 444 -D ${appimageContents}/responsively.desktop -t $out/share/applications
      fi
      if [ -d ${appimageContents}/usr/share/icons ]; then
        cp -r ${appimageContents}/usr/share/icons $out/share
      fi
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
