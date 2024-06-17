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
  
  features.network.hostName = "neoscode-server";
}
