{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  ...
}: {
  imports = [
    ./hardware.nix
    ../../base/server
  ];
}
