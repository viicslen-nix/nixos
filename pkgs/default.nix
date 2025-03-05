{
  inputs,
  pkgs,
  ...
}: {
  myVimPlugins = import ./vim-plugins {inherit pkgs;};
  iso-image = import ./iso {inherit inputs pkgs;};
}
