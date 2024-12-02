# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{pkgs ? import <nixpkgs> {}, ...}: rec {
  tabby-terminal = pkgs.callPackage ./tabby-terminal/package.nix {};
  draw-on-your-screen2 = pkgs.callPackage ./draw-on-your-screen2 {};
  # thorium = pkgs.callPackage ./thorium/package.nix {};
  # jetbrains = pkgs.callPackage ./jetbrains {};
  nushellPlugins.highlight = pkgs.callPackage ./nushell/plugins/highlight.nix {};
}
