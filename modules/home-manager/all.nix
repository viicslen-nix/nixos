{
  lib,
  inputs,
  ...
}:
with lib; {
  imports = builtins.concatLists [
    [
      inputs.nvchad.homeManagerModule
      ezModules.defaults
    ]
    (attrsets.mapAttrsToList (_name: value: value) ezModules.functionality)
    (attrsets.mapAttrsToList (_name: value: value) ezModules.programs)
  ];
}
