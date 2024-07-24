# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{pkgs ? import <nixpkgs> {}, ...}: rec {
  tabby-terminal = pkgs.callPackage ./tabby-terminal/package.nix {};
  # thorium = pkgs.callPackage ./thorium/package.nix {};
  # jetbrains = pkgs.callPackage ./jetbrains {};
}
