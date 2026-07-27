{
  lib,
  pkgs,
  inputs,
  nixosModules,
  homeModules,
  config,
  users,
  ...
}:
with lib; {
  imports = [
    inputs.nixos-hardware.nixosModules.asus-zephyrus-gu603h
    inputs.disko.nixosModules.disko
    (import ./disko.nix {device = "/dev/disk/by-id/nvme-WD_BLACK_SN770_1TB_223766801969";})
    ./hardware.nix

    nixosModules.asus
    nixosModules.intel
    nixosModules.nvidia
    nixosModules.display
    nixosModules.razer
    nixosModules.mullvad
    nixosModules.steam

    # Imported for its options; disabled below.
    nixosModules.backups
  ];

  home-manager.sharedModules = [
    homeModules.kitty

    ({lib, pkgs, inputs, ...}: {
      modules = {
        functionality.impermanence = {
          enable = false;
          share = [
            "JetBrains"
            "keyrings"
            "direnv"
            "zoxide"
            "pnpm"
            "nvim"
          ];
          config = [
            "Lens"
            "Slack"
            "Ferdium"
            "Insomnia"
            "JetBrains"
            "GitHub Desktop"
            "github-copilot"
            "warp-terminal"
            "composer"
            "discord"
            "legcord"
            "direnv"
            "gcloud"
            "helm"
          ];
          cache = [
            "JetBrains"
            "carapace"
            "zoxide"
            "helm"
          ];
          directories = [
            ".pki"
            ".ssh"
            ".kube"
            ".java"
            ".gnupg"
            ".nixops"
            ".thunderbird"
          ];
          files = [
            ".env.aider"
            ".gitconfig"
            ".wakatime.cfg"
          ];
        };
    
      };
    
      xdg = {
        configFile = {
          "gh/hosts.yml".source = (pkgs.formats.yaml {}).generate "hosts.yml" {
            "github.com" = {
              user = "viicslen";
              git_protocol = "https";
              users = {
                viicslen = "";
              };
            };
          };
        };
      };
    
      dconf.settings = {
        "org/gnome/shell" = {
          favorite-apps = [
            "org.gnome.Nautilus.desktop"
            "zen.desktop"
            "phpstorm.desktop"
            "ghostty.desktop"
            "legcord.desktop"
          ];
        };
    
        "org/gnome/shell/extensions/arcmenu" = {
          menu-button-border-color = lib.hm.gvariant.mkTuple [true "transparent"];
          menu-button-border-radius = lib.hm.gvariant.mkTuple [true 10];
        };
    
        "org/gnome/desktop/wm/preferences".button-layout = lib.mkForce ":minimize,maximize,close";
      };
    
      wayland.windowManager.hyprland.settings = {
        monitor = [
          "eDP-1,2560x1600@60,0x0,1.6"
        ];
      };
    
      home.file.".config/hypr/pyprland.toml".text = lib.mkAfter ''
        [monitors.placement."G276HL"]
        topOf = "eDP-1"
    
        [monitors.placement."G274F"]
        leftOf = "eDP-1"
    
        [monitors.placement."Acer CB281HK"]
        topOf = "G274F"
        scale = 1.875000
      '';
    }
    )
  ];

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
