{
  lib,
  inputs,
  outputs,
  ...
}:
with lib; {
  imports = builtins.concatLists [
    [
      inputs.home-manager.nixosModules.default
      inputs.nur.modules.nixos.default
      inputs.agenix.nixosModules.default
      inputs.niri.nixosModules.default
      outputs.nixosModules.containers
    ]
    (attrsets.mapAttrsToList (_name: value: value) outputs.nixosModules.presets)
    (attrsets.mapAttrsToList (_name: value: value) outputs.nixosModules.desktop)
    (attrsets.mapAttrsToList (_name: value: value) outputs.nixosModules.hardware)
    (attrsets.mapAttrsToList (_name: value: value) outputs.nixosModules.programs)
    (attrsets.mapAttrsToList (_name: value: value) outputs.nixosModules.functionality)
  ];
}
