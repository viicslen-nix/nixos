{
  pkgs,
  inputs,
  ...
}:
inputs.nixos-generators.nixosGenerate {
  inherit pkgs;
  format = "install-iso";
  modules = [
    ./configuration.nix
  ];
}
