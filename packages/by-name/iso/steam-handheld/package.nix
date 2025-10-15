{
  pkgs,
  inputs,
  ...
}:
inputs.nixos-generators.nixosGenerate {
  inherit pkgs;
  format = "install-iso";
  modules = [
    ../common/configuration.nix
    ./configuration.nix
  ];
}
