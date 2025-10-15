{
  pkgs,
  inputs,
  ...
}:
inputs.nixos-generators.nixosGenerate {
  inherit pkgs;
  format = "install-iso";
  modules = [
    inputs.chaotic.nixosModules.default
    inputs.jovian.nixosModules.default
    ./configuration.nix
  ];
}
