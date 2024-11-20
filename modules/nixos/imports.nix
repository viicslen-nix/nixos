{
  lib,
  outputs,
  ...
}: with lib; {
  imports = builtins.concatLists [
    [
      outputs.nixosModules.containers
    ]
    (attrsets.mapAttrsToList (name: value: value) outputs.nixosModules.presets)
    (attrsets.mapAttrsToList (name: value: value) outputs.nixosModules.desktop)
    (attrsets.mapAttrsToList (name: value: value) outputs.nixosModules.hardware)
    (attrsets.mapAttrsToList (name: value: value) outputs.nixosModules.programs)
    (attrsets.mapAttrsToList (name: value: value) outputs.nixosModules.functionality)
  ];
}
