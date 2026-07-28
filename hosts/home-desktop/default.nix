{
  lib,
  pkgs,
  inputs,
  nixosModules,
  config,
  users,
  ...
}:
with lib; {
  imports = [
    inputs.disko.nixosModules.disko
    (import ./disko.nix {device = "/dev/disk/by-uuid/2da72401-b2b8-4a0d-8324-fd474124f51e";})
    ./hardware.nix

    nixosModules.hardware.intel
    nixosModules.hardware.nvidia
    nixosModules.hardware.razer
    nixosModules.programs.steam
  ];

  # (no host-specific home-manager config)
  services.displayManager.defaultSession = "niri";

  boot = {
    binfmt.emulatedSystems = ["aarch64-linux"];
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

    loader = {
      efi.canTouchEfiVariables = false;
      efi.efiSysMountPoint = "/boot/efi";

      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        configurationLimit = 10;
      };
    };
  };

  networking = {
    hostId = "86f2c355";
    hostName = "home-desktop";
  };

  users = {
    mutableUsers = false;
    extraUsers.root.hashedPassword = "$6$hl2eKy3qKB3A7hd8$8QMfyUJst4sRAM9e9R4XZ/IrQ8qyza9NDgxRbo0VAUpAD.hlwi0sOJD73/N15akN9YeB41MJYoAE9O53Kqmzx/";
  };

  environment.systemPackages = with pkgs; [
    vscode
    discord
    uv
    rpi-imager
    pkgs.inputs.ambxst.default
  ];

  modules = {
    hardware.nvidia.latest = true;

    desktop = {
      niri.enable = true;

      hyprland = {
        enable = true;
        portals = {
          enable = true;
          backend = "gtk";
          extraBackends = ["gnome"];
        };
        hyprsplit.enable = true;
        hyprVariables = {
          XDG_CURRENT_DESKTOP = "Hyprland";
          XDG_SESSION_DESKTOP = "Hyprland";
          XCURSOR_SIZE = builtins.toString config.stylix.cursor.size;

          # NVidia
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          LIBVA_DRIVER_NAME = "nvidia";
          __GL_GSYNC_ALLOWED = "1";
          __GL_VRR_ALLOWED = "0";
        };
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
      };
    };

    programs = {
      docker = {
        nvidiaSupport = true;
        storageDriver = "btrfs";
      };

      onePassword.autostart = true;
    };
  };
}
