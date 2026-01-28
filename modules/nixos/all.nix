{
  lib,
  inputs,
  outputs,
  ...
}:
with lib; {
  imports = builtins.concatLists [
    (attrsets.mapAttrsToList (_name: value: value) outputs.nixosModules.desktop)
    (attrsets.mapAttrsToList (_name: value: value) outputs.nixosModules.hardware)
    (attrsets.mapAttrsToList (_name: value: value) outputs.nixosModules.programs)
    (attrsets.mapAttrsToList (_name: value: value) outputs.nixosModules.core)
    (attrsets.mapAttrsToList (_name: value: value) outputs.nixosModules.services)
    (attrsets.mapAttrsToList (_name: value: value) outputs.nixosModules.features)
  ];
}
