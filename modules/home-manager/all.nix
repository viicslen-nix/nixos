{
  lib,
  inputs,
  outputs,
  ...
}:
with lib; {
  home-manager.sharedModules = builtins.concatLists [
    (attrsets.mapAttrsToList (_name: value: value) outputs.homeManagerModules.functionality)
    (attrsets.mapAttrsToList (_name: value: value) outputs.homeManagerModules.programs)
  ];
}
