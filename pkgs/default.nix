{
  inputs,
  pkgs,
  lib,
  ...
}: {
  myVimPlugins = import ./vim-plugins {inherit pkgs;};
  myScripts = import ./scripts {inherit pkgs;};
  vial = pkgs.callPackage ./by-name/vi/vial {};
  electron_36-bin = pkgs.callPackage ./by-name/el/electron_36 {};
  iso = lib.recurseIntoAttrs (pkgs.callPackage ./iso {inherit inputs pkgs;});
}
