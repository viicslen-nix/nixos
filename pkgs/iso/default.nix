{
  pkgs,
  inputs,
  lib,
  ...
}:
lib.makeScope pkgs.newScope (self: with self; {
  common = callPackage ./common.nix { inherit inputs pkgs lib;};
})
