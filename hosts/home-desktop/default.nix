{
  lib,
  pkgs,
  inputs,
  config,
  users,
  ...
}:
with lib; {
  imports = [
    inputs.disko.nixosModules.disko
    (import ./disko.nix {device = "/dev/disk/by-uuid/2da72401-b2b8-4a0d-8324-fd474124f51e";})
    ./hardware.nix
  ];

  home-manager.sharedModules = [./home.nix];
  services.displayManager.defaultSession = "gnome";

  boot = {
    plymouth.enable = true;
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
    firewall.enable = mkForce false;
  };

  # Add root user for troubleshooting
  users = {
    mutableUsers = false;
    extraUsers.root.hashedPassword = "$6$hl2eKy3qKB3A7hd8$8QMfyUJst4sRAM9e9R4XZ/IrQ8qyza9NDgxRbo0VAUpAD.hlwi0sOJD73/N15akN9YeB41MJYoAE9O53Kqmzx/";
  };

  environment.systemPackages = with pkgs; [
    jetbrains-toolbox
    vscode
    lens
    insomnia
    drawing
    kooha
    obsidian
    drawio
    legcord
    discord
    fish
    dbeaver-bin
    uv
    rpi-imager
  ];

  modules = {
    hardware = {
      intel.enable = true;

      nvidia = {
        enable = true;
        latest = true;
      };
    };

    desktop = {
      gnome.enable = true;

      hyprland = {
        enable = true;
        portals = {
          enable = true;
          backend = "gnome";
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

    services = {
      oom.enable = true;
      powerManagement.enable = true;
    };

    features.appImages.enable = true;

    core = {
      theming.enable = true;

      network.hosts = {
        # Docker
        "kubernetes.docker.internal" = "127.0.0.1";
        "host.docker.internal" = "127.0.0.1";

        # Remote
        "webapps" = "50.116.36.170";
        "storesites" = "23.239.17.196";
        "db-prod-master" = "50.116.56.10";
        "db-prod-read" = "50.116.56.249";
        "db-staging-master" = "45.79.180.78";
        "db-staging-read" = "45.79.180.88";

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
      ld.enable = true;
      steam.enable = true;
      docker = {
        enable = true;
        nvidiaSupport = true;
        storageDriver = "btrfs";
        allowTcpPorts = [
          # Traefik
          80
          443
          8080

          # PHPStorm Xdebug
          9003

          # Portainer
          9443

          # MySQL
          3306

          # Ray
          23517
        ];
      };

      onePassword = {
        enable = true;
        autostart = true;
        gitSignCommits = true;
        allowedCustomBrowsers = [
          ".zen-wrapped"
          "zen"
          "vivaldi"
          "vivaldi-stable"
          "vivaldi-snapshot"
        ];
        users = attrNames users;
      };
    };
  };
}
