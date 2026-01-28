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
    inputs.nixos-hardware.nixosModules.asus-zephyrus-gu603h
    inputs.disko.nixosModules.disko
    (import ./disko.nix {
      inherit inputs;
      device = "/dev/disk/by-id/nvme-WD_BLACK_SN770_1TB_223766801969";
    })
    ./hardware.nix
  ];

  home-manager.sharedModules = [./home.nix];

  boot = {
    plymouth.enable = true;
    binfmt.emulatedSystems = ["aarch64-linux"];

    loader = {
      efi.canTouchEfiVariables = false;

      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        configurationLimit = 10;
      };
    };
  };

  hardware = {
    openrazer = {
      enable = true;
      users = attrNames users;
    };
  };

  networking = {
    hostId = "86f2c355";
    hostName = "asus-zephyrus-gu603";
    firewall.enable = mkForce false;
  };

  # Add root user for troubleshooting
  users = {
    mutableUsers = false;
    extraUsers.root.hashedPassword = "$6$hl2eKy3qKB3A7hd8$8QMfyUJst4sRAM9e9R4XZ/IrQ8qyza9NDgxRbo0VAUpAD.hlwi0sOJD73/N15akN9YeB41MJYoAE9O53Kqmzx/";
  };

  services = {
    displayManager.defaultSession = "niri";

    # Disable the built-in keyboard
    udev.extraRules = lib.mkAfter ''
      KERNEL=="event*", ATTRS{name}=="AT Translated Set 2 keyboard", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    '';
  };

  environment.systemPackages = with pkgs; [
    # jetbrains.idea-ultimate
    # jetbrains.phpstorm
    # jetbrains.datagrip
    # jetbrains.webstorm
    # jetbrains.goland
    jetbrains-toolbox
    vscode
    lens
    insomnia
    drawing
    kooha
    obsidian
    drawio
    legcord
    fish
    windsurf
    pkgs.inputs.zen-browser.default
    dbeaver-bin
    uv
  ];

  # programs.ssh.askPassword = mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
  # programs.ssh.askPassword = mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";

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
      gnome.enable = true;
      niri.enable = true;

      # hyprland = {
      #   enable = true;
      #   gnomeCompatibility = true;
      #   hyprVariables = {
      #     XDG_CURRENT_DESKTOP = "Hyprland";
      #     XDG_SESSION_DESKTOP = "Hyprland";
      #     XCURSOR_SIZE = builtins.toString config.stylix.cursor.size;
      #
      #     # NVidia
      #     GBM_BACKEND = "nvidia-drm";
      #     __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      #     LIBVA_DRIVER_NAME = "nvidia";
      #     __GL_GSYNC_ALLOWED = "1";
      #     __GL_VRR_ALLOWED = "0";
      #   };
      # };

      # kde = {
      #   enable = true;
      #   enableSddm = false;
      # };
    };

    services = {
      oom.enable = true;
      power-management.enable = true;

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
        enable = true;
        directories = [
          "/etc/mullvad-vpn"
          "/etc/gdm"
        ];
      };
    };

    features.app-images.enable = true;

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
        "labreu.test" = "127.0.0.1";
        "store.labreu.test" = "127.0.0.1";
      };
    };

    presets = {
      base.enable = true;
      work.enable = true;
      personal.enable = true;
    };

    programs = {
      mullvad.enable = true;
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
        gitSignCommits = true;
        allowedCustomBrowsers = [
          ".zen-wrapped"
          "zen"
        ];
        users = attrNames users;
      };
    };

    containers.postgres.enable = true;
  };
}
