# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  lib,
  users,
  ...
}:
with lib; {
  imports = [
    # Include the results of the hardware scan.
    ./hardware.nix
  ];

  system.stateVersion = "25.05";
  home-manager.sharedModules = [./home.nix];

  boot = {
    plymouth.enable = true;

    loader = {
      efi.canTouchEfiVariables = true;

      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
    };
  };

  networking = {
    hostName = "dostov-dev";
    firewall.enable = mkForce false;
  };

  users.users = {
    dostov = {
      isNormalUser = true;
      description = "dostov";
      extraGroups = ["networkmanager" "wheel"];
    };

    neoscode.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOaNSsNMlFN0+bSryhAdcS38d0Egk/M3SvzP4Yb4Wf4H dostov@dostov-dev"
    ];
  };

  services = {
    xserver.displayManager.gdm.enable = true;

    openssh = {
      enable = true;
      startWhenNeeded = true;
      passwordAuthentication = true;
    };
  };

  environment.systemPackages = with pkgs; [
    microsoft-edge-wayland
    jetbrains.idea-ultimate
    jetbrains.phpstorm
    jetbrains.datagrip
    jetbrains.webstorm
    jetbrains.goland
    github-desktop
    insomnia
    obsidian
    legcord
    drawing
    vscode
    code-cursor
    windsurf
    drawio
    kooha
    lens
  ];

  modules = {
    hardware = {
      intel.enable = true;
      nvidia.enable = true;

      display = {
        enable = true;
        resolution = "1920x1080";
        refreshRate = "60";
        port = "HDMI-A-1";
      };
    };

    desktop.kde = {
      enable = true;
      enableSddm = false;
    };

    functionality = {
      oom.enable = true;
      theming.enable = true;
      appImages.enable = true;
      powerManagement.enable = true;

      network.hosts = {
        # Docker
        "kubernetes.docker.internal" = "127.0.0.1";
        "host.docker.internal" = "127.0.0.1";

        # Remote
        "webapps" = "REDACTED";
        "storesites" = "REDACTED";
        "db-prod-master" = "50.116.56.10";
        "db-prod-read" = "50.116.56.249";
        "db-staging-master" = "45.79.180.78";
        "db-staging-read" = "45.79.180.88";

        # Development
        "ai.local" = "127.0.0.1";
        "home.local" = "127.0.0.1";
        "buggregator.local" = "127.0.0.1";
        "npm.local" = "127.0.0.1";
        "portainer.local" = "127.0.0.1";
        "phpmyadmin.local" = "127.0.0.1";
        "selldiam.test" = "127.0.0.1";
        "mylisterhub.test" = "127.0.0.1";
        "app.mylisterhub.test" = "127.0.0.1";
        "admin.mylisterhub.test" = "127.0.0.1";
        "*.mylisterhub.test" = "127.0.0.1";
      };
    };

    presets = {
      base.enable = true;
      work.enable = true;
      personal.enable = true;
    };

    programs = {
      mullvad.enable = true;

      docker = {
        enable = true;
        nvidiaSupport = true;
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
        users = attrNames users;
      };
    };
  };
}
