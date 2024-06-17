{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  user,
  ...
}: {
  imports = [
    ./hardware.nix
    ../../base/nixos
    ../../base/work
  ];
}
