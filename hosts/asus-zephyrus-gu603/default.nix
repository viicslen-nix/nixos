{
  lib,
  pkgs,
  inputs,
  users,
  ...
}:
with lib; {
  imports = [
    inputs.nixos-hardware.nixosModules.asus-zephyrus-gu603h
    inputs.disko.nixosModules.disko
    (import ./disko.nix {
      inherit inputs;
      device = "/dev/nvme0n1";
    })
    ./hardware.nix
  ];

  system.stateVersion = "25.05";

  home-manager.shareModules = [./home.nix];

  boot = {
    plymouth.enable = true;

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
    logitech.wireless.enable = true;
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

  age = {
    identityPaths = map (user: "${config.users.users.${user.name}.home}/.ssh/agenix") users;

    secrets = {
      intelephense.file = ../../secrets/intelephense/licence.age;
    };
  };

  services = {
    displayManager.defaultSession = "hyprland-uwsm";

    # Disable the built-in keyboard
    udev.extraRules = lib.mkAfter ''
      KERNEL=="event*", ATTRS{name}=="AT Translated Set 2 keyboard", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    '';
  };

  users.users =
    lib.attrsets.mapAttrs' (name: value: (nameValuePair name {
      isNormalUser = true;
      description = value.description;
      initialPassword = lib.mkIf (value.password == "") name;
      hashedPassword = lib.mkIf (value.password != "") value.password;
      extraGroups = ["networkmanager" "wheel" "adbusers" name];
      shell = pkgs.nushell;
      useDefaultShell = false;
    }))
    users;

  environment.systemPackages = with pkgs; [
    jetbrains-toolbox
    jetbrains.idea-ultimate
    jetbrains.phpstorm
    jetbrains.datagrip
    jetbrains.webstorm
    jetbrains.goland
    vscode
    waveterm
    lens
    skypeforlinux
    insomnia
    tangram
    endeavour
    drawing
    kooha
    vscode
    obsidian
    drawio
  ];

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
        users = attrNames users;
      };

      hyprland = {
        enable = true;
        gnomeCompatibility = true;
        users = attrNames users;
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
      kanata.users = attrNames users;
      mkcert.rootCA.users = attrNames users;

      mullvad.enable = true;

      docker = {
        nvidiaSupport = true;
        users = attrNames users;
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
  };
}
