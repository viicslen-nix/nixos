{
  lib,
  inputs,
  self,
  ...
}:
with lib; {
  imports = builtins.concatLists [
    [
      inputs.nur.modules.nixos.default
      inputs.agenix.nixosModules.default
      inputs.chaotic.nixosModules.default
      self.outputs.nixosModules.containers
    ]
    (attrsets.mapAttrsToList (_name: value: value) self.outputs.nixosModules.presets)
    (attrsets.mapAttrsToList (_name: value: value) self.outputs.nixosModules.desktop)
    (attrsets.mapAttrsToList (_name: value: value) self.outputs.nixosModules.hardware)
    (attrsets.mapAttrsToList (_name: value: value) self.outputs.nixosModules.programs)
    (attrsets.mapAttrsToList (_name: value: value) self.outputs.nixosModules.functionality)
  ];
}
