{
  lib,
  pkgs,
  users,
  inputs,
  nixosModules,
  homeModules,
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
    nixosModules.desktop.kde
    nixosModules.programs.mullvad
    nixosModules.containers.vitess

    # Declares `services.miami-bus-tracker`, outside the modules.* namespace
    nixosModules.features.miami-bus-tracker
  ];

  home-manager.sharedModules = [
    homeModules.programs.ray
    homeModules.programs.kitty
    homeModules.programs.tinkerwell
    homeModules.programs.zen-browser
    homeModules.programs.vivaldi
    homeModules.programs.webapps

    ({lib, pkgs, osConfig, ...}: {
    
      home.file.".config/hypr/pyprland.toml".text = lib.mkAfter ''
        [monitors.placement."LW9AA0048525"]
        rightOf = "DP-1"
        transform = 1
      '';
    
      home.autostart = [
        {
          package = pkgs.mullvad-vpn;
          args = ["--silent"];
          delay = 5;
        }
        {
          package = pkgs.jetbrains-toolbox;
          delay = 5;
        }
      ];
    
      wayland.windowManager.hyprland.settings = lib.mkIf osConfig.programs.hyprland.enable {
        monitor = [
          "DP-1, 1920x1080@59.99, 0x0, 1, vrr, 0"
          "DP-2, 1920x1080@59.99, 1920x0, 1, transform, 3, vrr, 0"
          ", preferred, auto, 1"
        ];
      };
    
      programs.niri.settings = lib.mkIf osConfig.programs.niri.enable {
        # outputs = {
        #   "DP-1" = {
        #     scale = 1.0;
        #     position = {
        #       x = 1920;
        #       y = 0;
        #     };
        #     mode = {
        #       width = 1920;
        #       height = 1080;
        #       refresh = 59.997;
        #     };
        #   };
        #   "DP-2" = {
        #     scale = 1.0;
        #     position = {
        #       x = 0;
        #       y = 0;
        #     };
        #     mode = {
        #       width = 1920;
        #       height = 1080;
        #       refresh = 59.997;
        #     };
        #     focus-at-startup = true;
        #     transform.rotation = 90;
        #   };
        # };
    
        workspaces = {
          "browser" = {
            name = "Browser";
            open-on-output = "DP-1";
          };
          "editor" = {
            name = "Editor";
            open-on-output = "DP-1";
          };
          "communication" = {
            name = "Communication";
            open-on-output = "DP-2";
          };
          "system" = {
            name = "System";
            open-on-output = "DP-2";
          };
        };
    
        binds = {
          "Mod+F1".action.spawn = ["zen-browser"];
          "Mod+F2".action.spawn = ["phpstorm"];
          "Mod+F3".action.spawn = ["legcode" "--split=top" "kitty" "--split=bottom"];
          "Mod+F4".action.spawn = ["code" "--split=top" "kitty" "--split=bottom"];
        };
      };
    
      programs.dank-material-shell.niri.includes.filesToInclude = [
        "custom"
      ];
    }
    )
  ];

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

    cloudflared = {
      enable = true;
      tunnels = {
        "0998f771c-00d1-4caa-9c82-de93b57c89a0" = {
          credentialsFile = "/home/neoscode/.cloudflared/998f771c-00d1-4caa-9c82-de93b57c89a0.json";
          default = "http_status:404";
        };
      };
    };
  };

  programs = {
    wireshark.enable = true;
  };

  # Force-install Violentmonkey into chromium (used by the webapps module).
  # Must be "<id>;<update_url>" — a bare id no-ops; chromium needs the Web Store
  # update URL to actually fetch the extension.
  environment.etc."chromium/policies/managed/webapps.json".text = builtins.toJSON {
    ExtensionInstallForcelist = [
      "jinjaccalgkegednnccohejagnlnfdag;https://clients2.google.com/service/update2/crx"
    ];
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
      # niri comes from the niri subflake module, imported by the desktop preset
      niri.enable = true;

      kde = {
        enableSddm = false;
        useGnomeKeyring = true;
      };
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
