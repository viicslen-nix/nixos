{
  lib,
  pkgs,
  inputs,
  nixosModules,
  ...
}:
with lib; {
  imports = [
    # Include the results of the hardware scan.
    ./hardware.nix
    inputs.ghost-backup.nixosModules.default

    nixosModules.hardware.intel
    nixosModules.hardware.nvidia
    nixosModules.hardware.bluetooth
    nixosModules.hardware.razer
    nixosModules.programs.mullvad
    nixosModules.containers.vitess
    nixosModules.features.miami-bus-tracker
  ];

  home-manager.sharedModules = [./home.nix];

  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };

      grub = {
        configurationLimit = 10;
        efiSupport = true;
        device = "nodev";
      };

      systemd-boot.enable = false;
    };
  };

  networking = {
    hostName = "dostov-dev";
  };

  nix.settings.max-jobs = lib.mkDefault 12;

  users.users = {
    dostov = {
      isNormalUser = true;
      description = "dostov";
      extraGroups = ["networkmanager" "wheel" "wireshark"];
    };

    neoscode = {
      extraGroups = ["wireshark"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOaNSsNMlFN0+bSryhAdcS38d0Egk/M3SvzP4Yb4Wf4H dostov@dostov-dev"
      ];
    };
  };

  services = {
    blueman.enable = true;
    tailscale.enable = true;
    ghost-backup.enable = true;

    displayManager = {
      defaultSession = "niri";
      gdm.enable = false;
    };

    miami-bus-tracker = {
      enable = true;
      stopId = "1340";
      routeId = "836";
      direction = "Westbound";
      notification = true;
      notifyMinutes = 10;
      activeTimeStart = "22:00"; # UTC
      activeTimeEnd = "23:59"; # UTC
    };

    openssh = {
      enable = true;
      startWhenNeeded = true;
      settings = {
        PasswordAuthentication = false;
        AllowUsers = ["neoscode"];
      };
    };
  };

  programs = {
    wireshark.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # Browsers
    google-chrome
    brave

    # IDEs & Editors
    unstable.vscode-fhs
    unstable.code-cursor-fhs

    # Development Tools
    ghostty
    postman

    # Communication
    discordo
    discord

    # Office
    onlyoffice-desktopeditors

    # Windows
    winboat
    freerdp
    iptables

    # Misc
    tlrc
    vial
    uv
    wireshark
  ];

  modules = {
    desktop = {
      niri.enable = true;
    };

    core = {
      theming.disabledTargets = ["chromium"];

      network.hosts = {
        # Local Dev
        "erpnext.test" = "127.0.0.1";
        "selldiam.test" = "127.0.0.1";
        "mylisterhub.test" = "127.0.0.1";
        "vite.mylisterhub.test" = "127.0.0.1";
        "app.mylisterhub.test" = "127.0.0.1";
        "admin.mylisterhub.test" = "127.0.0.1";
        "*.mylisterhub.test" = "127.0.0.1";
      };
    };

    programs = {
      mkcert = {
        rootCA = {
          enable = false;
          # certPath = config.age.secrets.mkcert-rootCA.path;
          # keyPath = config.age.secrets.mkcert-rootCA-key.path;
        };
        domains = [
          "erpnext.test"
          "selldiam.test"
          "mylisterhub.test"
          "*.mylisterhub.test"
        ];
      };

      docker.nvidiaSupport = true;
    };
  };
}
