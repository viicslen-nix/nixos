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

  # Don't raise these or set cores = 0 — 31G cannot feed 32 threads of compiler.
  nix.settings = {
    max-jobs = lib.mkDefault 4;
    cores = lib.mkDefault 8;
  };

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
    ghost-backup.enable = true;

    tailscale = {
      enable = true;
      openFirewall = true;
      extraUpFlags = ["--ssh"];
    };

    displayManager = {
      defaultSession = "niri";
      gdm.enable = false;
    };

    miami-bus-tracker = {
      enable = true;
      stopId = "590"; # SE 1 ST & 1 AV
      routeId = "836";
      direction = "Westbound";
      notification = true;
      notifyMinutes = 10;
      activeTimeStart = "16:30";
      activeTimeEnd = "20:00";
    };

    openssh = {
      enable = true;
      startWhenNeeded = true;
      settings = {
        PasswordAuthentication = false;
        AllowUsers = ["neoscode"];
      };
    };

    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      loadModels = ["qwen3.5:9b"];
      environmentVariables = {
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_CONTEXT_LENGTH = "8192";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
      };
    };
  };

  programs = {
    wireshark.enable = true;
  };

  # The 6605DN is IPP 1.1 only, so `model = "everywhere"` cannot drive it — it needs this PPD.
  services.printing.drivers = [
    (pkgs.runCommand "xerox-wc6605dn-ppd" {} ''
      install -Dm444 ${./xerox-wc6605dn.ppd} $out/share/cups/model/Xerox-WorkCentre-6605DN.ppd
    '')
  ];

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Xerox-WorkCentre-6605DN";
        location = "Office";
        # Raw PDL port, not ipp:// — this firmware's IPP stack drops Get-Printer-Attributes.
        # mDNS name, not the DHCP address: it is derived from the MAC and never moves.
        deviceUri = "socket://XRX9C934E127ECD.local:9100";
        model = "Xerox-WorkCentre-6605DN.ppd";
      }
    ];
    ensureDefaultPrinter = "Xerox-WorkCentre-6605DN";
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
      shell = "dms";

      niri.enable = true;

      hyprland = {
        enable = true;
        layout = "scrolling";
      };

      monitors = {
        DP-2.rotation = 90;
        DP-1.position = {
          x = 1080;
          y = 635;
        };
      };
    };
    containers.settings = {
      backend = "podman";
      userns = "auto";
      nvidiaSupport = true;
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
      mkcert.domains = [
        "erpnext.test"
        "selldiam.test"
        "mylisterhub.test"
        "*.mylisterhub.test"
      ];
    };
  };
}
