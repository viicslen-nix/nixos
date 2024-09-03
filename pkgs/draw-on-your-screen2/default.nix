{ lib
, stdenv
, fetchFromGitHub
, nixosTests
}: let
  uuid = "draw-on-your-screen2@zhrexl.github.com";
in stdenv.mkDerivation rec {
  pname = "draw-on-your-screen2";
  version = "12";

  src = fetchFromGitHub {
    owner = "zhrexl";
    repo = "DrawOnYourScreen2";
    rev = "v${version}";
    hash = "sha256-xmZ3IgezB1t8MeHtwtyiXqu0zEcQQyYpmzJ5TjcqI8E=";
  };

  nativeBuildInputs = with pkgs; [ buildPackages.glib ];

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
    maintainers = with maintainers; [ ];
    mainProgram = "draw-on-your-screen2";
    platforms = platforms.all;
  };
}
