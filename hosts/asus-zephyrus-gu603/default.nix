{
  lib,
  pkgs,
  inputs,
  nixosModules,
  users,
  ...
}:
with lib; {
  imports = [
    inputs.nixos-hardware.nixosModules.asus-zephyrus-gu603h
    inputs.disko.nixosModules.disko
    (import ./disko.nix {device = "/dev/disk/by-id/nvme-WD_BLACK_SN770_1TB_223766801969";})
    ./hardware.nix

    nixosModules.hardware.asus
    nixosModules.hardware.intel
    nixosModules.hardware.nvidia
    nixosModules.hardware.display
    nixosModules.hardware.razer
    nixosModules.programs.mullvad
    nixosModules.functionality.gaming

    # Imported for its options; disabled below.
    nixosModules.services.backups
  ];

  home-manager.sharedModules = [./home.nix];

  boot = {
    loader = {
      efi.canTouchEfiVariables = false;
      efi.efiSysMountPoint = "/boot/efi";

      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        configurationLimit = 10;
        efiInstallAsRemovable = true;
      };
    };
  };

  networking = {
    hostId = "86f2c355";
    hostName = "asus-zephyrus-gu603";
  };

  # Add root user for troubleshooting
  users = {
    mutableUsers = false;
    extraUsers.root.hashedPassword = "$6$hl2eKy3qKB3A7hd8$8QMfyUJst4sRAM9e9R4XZ/IrQ8qyza9NDgxRbo0VAUpAD.hlwi0sOJD73/N15akN9YeB41MJYoAE9O53Kqmzx/";
  };

  services = {
    # This host runs niri; "gnome" was never a registered session here.
    displayManager.defaultSession = "niri";

    # Disable the built-in keyboard
    udev.extraRules = lib.mkAfter ''
      KERNEL=="event*", ATTRS{name}=="AT Translated Set 2 keyboard", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    '';
  };

  programs.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/neoscode";
  };

  environment.systemPackages = with pkgs; [
    vscode-fhs
    uv
  ];

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

      #hyprland = {
      #  enable = false;
      #  nvidia = true;
      #  portals = {
      #    enable = true;
      #    backend = "gtk";
      #    extraBackends = ["gnome"];
      #  };
      #  globalVariables = {
      #    NVD_BACKEND = "direct";
      #    GBM_BACKEND = "nvidia-drm";
      #    LIBVA_DRIVER_NAME = "nvidia";
      #    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      #    __GL_GSYNC_ALLOWED = "1";
      #    __GL_VRR_ALLOWED = "0";
      #  };
      #};
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

    core = {
      network.hosts = {
        # Docker
        "kubernetes.docker.internal" = "127.0.0.1";
        "host.docker.internal" = "127.0.0.1";

        # Development
        "ai.local" = "127.0.0.1";
        "home.local" = "127.0.0.1";
        "buggregator.local" = "127.0.0.1";
        "soketi.local" = "127.0.0.1";
        "npm.local" = "127.0.0.1";
        "portainer.local" = "127.0.0.1";
        "phpmyadmin.local" = "127.0.0.1";
        "selldiam.test" = "127.0.0.1";
        "mylisterhub.test" = "127.0.0.1";
        "app.mylisterhub.test" = "127.0.0.1";
        "admin.mylisterhub.test" = "127.0.0.1";
        "*.mylisterhub.test" = "127.0.0.1";
        "time-tracker.test" = "127.0.0.1";
        "labreu.test" = "127.0.0.1";
        "store.labreu.test" = "127.0.0.1";
      };
    };

    programs = {
      docker = {
        nvidiaSupport = true;
        storageDriver = "btrfs";
      };
    };
  };
}
