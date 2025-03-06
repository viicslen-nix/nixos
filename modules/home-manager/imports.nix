{
  lib,
  inputs,
  config,
  ...
}:
with lib; {
  imports = [
    inputs.home-manager.nixosModules.default
  ];

  home-manager.sharedModules = builtins.concatLists [
    [
      inputs.nvchad.homeManagerModule
      config.flake.homeManagerModules.defaults
    ]
    (attrsets.mapAttrsToList (_name: value: value) config.flake.homeManagerModules.functionality)
    (attrsets.mapAttrsToList (_name: value: value) config.flake.homeManagerModules.programs)
  ];
}
