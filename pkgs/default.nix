{pkgs, ...}: rec {
  astalShells-tokyob0t = pkgs.callPackage ./astalShells/tokyob0t {};
  myVimPlugins = import ./vimPlugins { inherit pkgs; };
}
