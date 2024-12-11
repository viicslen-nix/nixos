{
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; {
  imports = [
    inputs.nixos-hardware.nixosModules.asus-zephyrus-gu603h
    (import ./disko.nix {
      inherit inputs;
      device = "/dev/nvme0n1";
    })
    ./hardware.nix
    ../../users/neoscode
  ];

  boot.loader = {
    efi.canTouchEfiVariables = false;

    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      configurationLimit = 10;
    };
  };

  networking = {
    hostId = "86f2c355";
    hostName = "asus-zephyrus-gu603";
    firewall.enable = mkForce false;
  };

  modules = {
    hardware = {
      asus.enable = true;
      intel.enable = true;

      nvidia = {
        enable = true;
        modern = true;
      };

      display = {
        enable = true;
        resolution = "2560x1600";
        refreshRate = "165";
        port = "eDP-1-1";
      };
    };

    desktop = {
      gnome = {
        enable = true;
        additionalExtensions = [
          pkgs.draw-on-your-screen2
        ];
      };

      hyprland = {
        enable = true;
        gnomeCompatibility = true;
      };
    };

    functionality = {
      oom.enable = true;
      theming.enable = true;
      appImages.enable = true;
      powerManagement.enable = true;

      backups = {
        enable = true;
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
        enable = true;
        directories = [
          "/etc/mullvad-vpn"
          "/etc/gdm"
        ];
      };
    };

    presets = {
      base.enable = true;
      work.enable = true;
      personal.enable = true;
    };

    programs = {
      docker.nvidiaSupport = true;

      github-runner = {
        enable = false;
        url = "https://github.com/FmTod";
        secrets.token = ../../secrets/github/runner.age;
      };
    };
  };

  hardware.logitech.wireless.enable = true;
  services.displayManager.defaultSession = "hyprland";
  environment.sessionVariables.GSK_RENDERER = "ngl";

  system.stateVersion = "25.05";
}
