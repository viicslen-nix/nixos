{
  inputs,
  pkgs,
  ...
}:
inputs.nixos-generators.nixosGenerate {
  inherit pkgs;
  format = "install-iso";
  modules = [
    inputs.disko.nixosModules.disko
    ./iso
  ];
}
