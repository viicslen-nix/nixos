{ pkgs, lib, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "responsively";
  version = "1.17.1";

  src = pkgs.fetchurl {
    url = "https://github.com/responsively-org/responsively-app/releases/download/v${version}/Responsively-App-${version}.x86_64.rpm";
    sha256 = lib.fakeSha256; # Replace with actual sha256 after first build
  };

  nativeBuildInputs = [ pkgs.rpmextract ];

  installPhase = ''
    mkdir -p $out
    cp -r usr/* $out/
  '';

  meta = with lib; {
    description = "A browser for responsive web development";
    homepage = "https://responsively.app/";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}
