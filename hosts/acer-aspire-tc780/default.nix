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

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 10;
    efi.canTouchEfiVariables = false;
  };

  features = {
    network.hostName = "acer-aspire-tc780";

    gnome = {
      enable = true;
      enableGdm = true;
      inherit user;
    };

    oom.enable = true;
    theming.enable = true;
    appImages.enable = true;
  };
}
