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
    ../../base/nixos
    ../../base/server
  ];
  
  features.network.hostName = "neoscode-server";
}
