{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  unzip,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "coderabbit";
  version = "0.4.2";

  src = fetchurl (
    if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64
    then {
      url = "https://cli.coderabbit.ai/releases/${finalAttrs.version}/coderabbit-linux-x64.zip";
      hash = "sha256-UICH1BOgiR4cOpNgmmW3Orp5wu3t62039hCuSl7O4/o=";
    }
    else if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch64
    then {
      url = "https://cli.coderabbit.ai/releases/${finalAttrs.version}/coderabbit-linux-arm64.zip";
      hash = "sha256-m3fnx8xKbKaYD8OI8I4HNNHCPgPeZbyKkC3nvq83CdY=";
    }
    else throw "Unsupported platform: ${stdenv.hostPlatform.system}"
  );

  nativeBuildInputs = [
    autoPatchelfHook
    unzip
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    install -Dm755 coderabbit $out/bin/coderabbit
    ln -s $out/bin/coderabbit $out/bin/cr

    runHook postInstall
  '';

  meta = {
    description = "CodeRabbit CLI for reviewing local changes and interacting with CodeRabbit AI";
    homepage = "https://coderabbit.ai";
    license = lib.licenses.unfree;
    mainProgram = "coderabbit";
    platforms = ["x86_64-linux" "aarch64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
