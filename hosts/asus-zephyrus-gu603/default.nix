{
  lib,
  inputs,
  users,
  nixosModules,
  ...
}:
with lib; {
  imports = [
    inputs.nixos-hardware.nixosModules.asus-zephyrus-gu603h
    inputs.disko.nixosModules.disko
    (import ../_shared/disko/btrfs-lvm.nix {device = "/dev/disk/by-id/nvme-WD_BLACK_SN770_1TB_223766801969";})
    ./hardware.nix

    nixosModules.hardware.asus
    nixosModules.hardware.intel
    nixosModules.hardware.nvidia
    nixosModules.hardware.display
    nixosModules.hardware.razer
    nixosModules.functionality.gaming

    # Imported for its options; disabled below.
    nixosModules.services.backups
  ];

  home-manager.sharedModules = [./home.nix];

  boot.loader = {
    efi.canTouchEfiVariables = false;
    grub.efiInstallAsRemovable = true;
  };

  networking = {
    hostId = "75203265";
    hostName = "asus-zephyrus-gu603";
  };

  services = {
    displayManager.defaultSession = "niri";

    # Disable the built-in keyboard
    udev.extraRules = lib.mkAfter ''
      KERNEL=="event*", ATTRS{name}=="AT Translated Set 2 keyboard", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    '';
  };

  modules = {
    hardware = {
      nvidia = {
        modern = true;
        prime = true;
        latest = true;
      };

      display = {
        resolution = "2560x1600";
        refreshRate = "165";
        port = "eDP-1-1";
      };
    };

    desktop = {
      niri.enable = true;
    };

    services = {
      backups = {
        enable = false;
        repository = "b2:viicslen-asus-zephyrus-gu603";

        secrets = {
          env = ../../secrets/restic/env.age;
          password = ../../secrets/restic/password.age;
        };

        exclude = [
          "vendor"
          "node_modules"
        ];

        home = {
          users = attrNames users;
          paths = [
            "Development"
            "Documents"
            "Pictures"
            "Videos"
            ".kube"
            ".nix"
          ];
        };
      };

      impermanence = {
        enable = false;
        directories = [
          "/etc/gdm"
        ];
      };
    };

    containers.settings.storageDriver = "btrfs";
  };
}
