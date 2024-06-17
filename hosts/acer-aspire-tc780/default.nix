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

  boot = {
    # Bootloader
    loader.systemd-boot.enable = true;
    loader.systemd-boot.configurationLimit = 10;
    loader.efi.canTouchEfiVariables = false;

    # Enable Plymouth
    plymouth.enable = true;
  };

  services.xserver = {
    # Enable the X11 windowing system.
    enable = true;

    # Configure keymap in X11
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

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
