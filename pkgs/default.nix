{
  inputs,
  pkgs,
  ...
}: {
  astalShells-tokyob0t = pkgs.callPackage ./astalShells/tokyob0t {};
  myVimPlugins = import ./vimPlugins {inherit pkgs;};
  iso-image = import ./iso {inherit inputs pkgs;};
}
