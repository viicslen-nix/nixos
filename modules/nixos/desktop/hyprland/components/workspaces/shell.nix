{ pkgs ? import <nixpkgs> {} }:
let
  work = import ./work.nix { inherit pkgs; };
in pkgs.mkShell {
  nativeBuildInputs = with pkgs.buildPackages; [
    work
  ];
}
