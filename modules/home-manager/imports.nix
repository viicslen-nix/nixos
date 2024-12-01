{
  lib,
  inputs,
  outputs,
  ...
}: with lib; {
  imports = [
    inputs.home-manager.nixosModules.default
  ];

  home-manager.sharedModules = builtins.concatLists [
    [
      inputs.home-manager.nixosModules.default
      outputs.homeManagerModules.autostart
    ]
    (attrsets.mapAttrsToList (name: value: value) outputs.homeManagerModules.programs)
  ];
}
