{
  inputs,
  pkgs,
  ...
}: {
  myVimPlugins = import ./vim-plugins {inherit pkgs;};
  myScripts = import ./scripts {inherit pkgs;};
  iso-image = import ./iso {inherit inputs pkgs;};
  vial = pkgs.callPackage ./by-name/vi/vial {};
  electron_36-bin = pkgs.callPackage ./by-name/el/electron_36 {};
}
