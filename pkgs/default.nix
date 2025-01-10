# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{pkgs ? import <nixpkgs> {}, inputs, ...}: rec {
  tabby-terminal = pkgs.callPackage ./tabby-terminal/package.nix {};
  draw-on-your-screen2 = pkgs.callPackage ./draw-on-your-screen2 {};
  nushellPlugins.highlight = pkgs.callPackage ./nushell/plugins/highlight.nix {};

  astalShells = {
    tokyob0t = pkgs.callPackage ./astalSHells/tokyob0t { astal = inputs.astal; };
  };
}
