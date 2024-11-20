{
  lib,
  outputs,
  ...
}: {
  imports = lib.attrsets.mapAttrsToList (name: value: value) outputs.nixosModules;
}
