{
  lib,
  pkgs,
  fetchurl,
}:
let
  version = "36.0.0-beta.9";
in pkgs.electron_35-bin.overrideAttrs {
  pname = "electron_36-bin";
  version = version;
  src = fetchurl {
    url = "https://github.com/electron/electron/releases/download/v${version}/electron-v${version}-linux-x64.zip";
    sha256 = "sha256-i09lv+qgpeA9P+WBPLosOxhpaLlgp0IbFdFZZaiCZOw=";
  };
}
