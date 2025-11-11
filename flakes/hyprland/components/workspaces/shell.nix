{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  packages = [
    (import ./work.nix {inherit pkgs;})
  ];
}
