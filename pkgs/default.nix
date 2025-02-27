{pkgs, ...}: rec {
  astalShells-tokyob0t = pkgs.callPackage ./astalShells/tokyob0t {};
  vimPlugins = import ./vimPlugins { inherit pkgs; };
}
