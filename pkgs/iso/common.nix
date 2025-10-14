{
  pkgs,
  inputs,
  lib,
  ...
}:
inputs.nixos-generators.nixosGenerate {
  inherit pkgs;
  format = "install-iso";
  modules = [
    ./common.nix
  ];
}
