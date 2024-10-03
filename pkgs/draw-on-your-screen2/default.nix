{
  lib,
  stdenv,
  fetchFromGitHub,
  nixosTests,
  pkgs,
}: let
  uuid = "draw-on-your-screen2@zhrexl.github.com";
in
  stdenv.mkDerivation rec {
    pname = "draw-on-your-screen2";
    version = "9b5c6633a1c2b8c5b35bac45276ad1302542ab9b";

    src = fetchFromGitHub {
      owner = "zhrexl";
      repo = "DrawOnYourScreen2";
      rev = "${version}";
      hash = "sha256-J4ljx3HBe+86PGOIIgabtj8AuUAf88/bpTfRXowUng4=";
    };

    nativeBuildInputs = with pkgs; [buildPackages.glib];

    buildPhase = ''
      runHook preBuild
      if [ -d schemas ]; then
        glib-compile-schemas --strict schemas
      fi
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/gnome-shell/extensions/
      cp -r -T . $out/share/gnome-shell/extensions/${uuid}
      runHook postInstall
    '';

    passthru = {
      extensionPortalSlug = pname;
      extensionUuid = uuid;

      tests = {
        gnome-extensions = nixosTests.gnome-extensions;
      };
    };

    meta = with lib; {
      description = "Start drawing with Super+Alt+D. Then save your beautiful work by taking a screenshot.";
      homepage = "https://github.com/zhrexl/DrawOnYourScreen2";
      changelog = "https://github.com/zhrexl/DrawOnYourScreen2/blob/${src.rev}/NEWS";
      license = licenses.gpl3Only;
      maintainers = with maintainers; [];
      mainProgram = "draw-on-your-screen2";
      platforms = platforms.all;
    };
  }
