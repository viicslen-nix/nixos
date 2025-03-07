{
  lib,
  inputs,
  outputs,
  ...
}:
with lib; {
  imports = builtins.concatLists [
    [
      inputs.nvchad.homeManagerModule
      outputs.homeManagerModules.defaults
    ]
    (attrsets.mapAttrsToList (_name: value: value) outputs.homeManagerModules.functionality)
    (attrsets.mapAttrsToList (_name: value: value) outputs.homeManagerModules.programs)
  ];
}
