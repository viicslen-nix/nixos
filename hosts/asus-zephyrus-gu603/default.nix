{
  lib,
  inputs,
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
    ../../users/neoscode
  ];

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
      gnome.enable = true;

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
      kanata.enable = false;
      mullvad.enable = true;
      docker.nvidiaSupport = true;

      github-runner = {
        enable = false;
        url = "https://github.com/FmTod";
        secrets.token = ../../secrets/github/runner.age;
      };

      onePassword = {
        enable = true;
        gitSignCommits = true;
        allowedCustomBrowsers = [
          ".zen-wrapped"
          "zen"
        ];
      };
    };
  };

  home-manager.users.neoscode = {
    modules.functionality.impermanence = {
      enable = true;
      share = [
        "Steam"
        "JetBrains"
        "keyrings"
        "direnv"
        "zoxide"
        "mkcert"
        "pnpm"
        "nvim"
        "atuin"
      ];
      config = [
        "Lens"
        "Code"
        "Slack"
        "Insomnia"
        "JetBrains"
        "1Password"
        "Tinkerwell"
        "Mullvad VPN"
        "GitHub Desktop"
        "microsoft-edge"
        "github-copilot"
        "tinkerwell"
        "composer"
        "discord"
        "legcord"
        "direnv"
        "gcloud"
        "helm"
        "op"
      ];
      cache = [
        "JetBrains"
        "starship"
        "carapace"
        "zoxide"
        "atuin"
        "helm"
      ];
      directories = [
        ".pki"
        ".ssh"
        ".zen"
        ".kube"
        ".java"
        ".gnupg"
        ".steam"
        ".nixops"
        ".vscode"
        ".docker"
        ".mozilla"
        ".thunderbird"
        ".tmux/resurrect"
      ];
      files = [
        ".env.aider"
        ".gitconfig"
        ".ideavimrc"
        ".zsh_history"
        ".wakatime.cfg"
        ".config/background"
        ".config/monitors.xml"
      ];
    };

    xdg = {
      configFile."gh/hosts.yml".source = (pkgs.formats.yaml {}).generate "hosts.yml" {
        "github.com" = {
          user = "viicslen";
          git_protocol = "https";
          users = {
            viicslen = "";
          };
        };
      };

      mimeApps = {
        enable = true;
        associations.added = {
          "text/html" = "org.gnome.Epiphany.desktop;microsoft-edge.desktop";
          "application/xhtml+xml" = "org.gnome.Epiphany.desktop;microsoft-edge.desktop";
          "x-scheme-handler/sms" = "org.gnome.Shell.Extensions.GSConnect.desktop";
          "x-scheme-handler/tel" = "org.gnome.Shell.Extensions.GSConnect.desktop";
          "x-scheme-handler/http" = "org.gnome.Epiphany.desktop;microsoft-edge.desktop";
          "x-scheme-handler/https" = "org.gnome.Epiphany.desktop;microsoft-edge.desktop";
          "x-scheme-handler/mailto" = "org.gnome.Geary.desktop";
        };
        defaultApplications = {
          "text/html" = "microsoft-edge.desktop";
          "application/xhtml+xml" = "microsoft-edge.desktop";
          "x-scheme-handler/http" = "microsoft-edge.desktop";
          "x-scheme-handler/https" = "microsoft-edge.desktop";
          "x-scheme-handler/mailto" = "org.gnome.Geary.desktop";
        };
      };
    };

    dconf.settings = {
      "org/gnome/shell" = {
        favorite-apps = [
          "org.gnome.Nautilus.desktop"
          "microsoft-edge.desktop"
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

    home.file."/home/neoscode/.config/mimeapps.list".force = lib.mkForce true;
  };

  hardware = {
    logitech.wireless.enable = true;
    openrazer.enable = true;
  };

  services.displayManager.defaultSession = "hyprland-uwsm";

  # Disable the built-in keyboard
  services.udev.extraRules = lib.mkAfter ''
    KERNEL=="event*", ATTRS{name}=="AT Translated Set 2 keyboard", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';

  environment.systemPackages = [
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

  system.stateVersion = "25.05";
}
