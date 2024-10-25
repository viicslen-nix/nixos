{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  user,
  ...
}:
with lib; {
  imports = [
    inputs.nixos-hardware.nixosModules.asus-zephyrus-gu603h
    inputs.disko.nixosModules.disko
    (import ./disko.nix {device = "/dev/nvme0n1";})
    ./hardware.nix
    ../../base/nixos
    ../../base/personal
    ../../base/work
  ];

  powerManagement.cpuFreqGovernor = "powersave";
  home-manager.users.${user} = import ./home.nix;
  age.identityPaths = ["${config.users.users.${user}.home}/.ssh/agenix"];

  boot = {
    kernelParams = [
      "video=eDP-1-1:2560x1600@165" # Patch for 165hz display
      "intel_iommu=on" # Hardware virtualisation
      "nvidia_drm.fbdev=1" # Nvidia DRM
    ];

    loader = {
      efi.canTouchEfiVariables = false;

      # systemd-boot.enable = true;

      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
      };
    };
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        libGL
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
        intel-media-driver
      ];
    };

    nvidia = {
      open = true;
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
    };

    logitech.wireless.enable = true;
  };

  specialisation = {
    nvidia-sync.configuration = {
      system.nixos.tags = ["nvidia-sync"];
      hardware.nvidia = {
        powerManagement.finegrained = lib.mkForce false;

        prime.offload.enable = lib.mkForce false;
        prime.offload.enableOffloadCmd = lib.mkForce false;

        prime.sync.enable = lib.mkForce true;
        dynamicBoost.enable = lib.mkForce true;
      };
    };
  };

  networking = {
    hostId = "86f2c355";
    hostName = "asus-zephyrus-gu603";
    firewall.enable = mkForce false;
  };

  environment.systemPackages = with pkgs; [
    asusctl
    supergfxctl
    zenith-nvidia
    nvtopPackages.nvidia
    gnomeExtensions.supergfxctl-gex
  ];

  services = {
    xserver = {
      enable = true;

      exportConfiguration = true;
      displayManager.sessionCommands = ''
        xrandr --newmode "2560x1600_165.00" 1047.00 2560 2800 3080 3600  1600 1603 1609 1763 -hsync +vsync
        xrandr --addmode eDP-1-1 "2560x1600_165.00"
        xrandr --output eDP-1-1 --mode 2560x1600 --rate 165
      '';

      videoDrivers = ["nvidia"];
    };

    supergfxd = {
      enable = true;
      settings = {
        vfio_enable = true;
        vfio_save = true;
        always_reboot = true;
        hotplug_type = "Asus";
      };
    };

    asusd = {
      enable = true;
      enableUserService = true;
    };

    tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 90;

        CPU_BOOST_ON_AC = 0;
        CPU_BOOST_ON_BAT = 0;
        CPU_HWP_DYN_BOOST_ON_AC = 0;
        CPU_HWP_DYN_BOOST_ON_BAT = 0;
        CPU_SCALING_GOVERNOR_ON_BATTERY = "powersave";
      };
    };

    power-profiles-daemon.enable = false;
  };

  programs.nh.flake = "/persist/home/${user}/.nix/";
  environment.sessionVariables.FLAKE = "/persist/home/${user}/.nix/";

  features = {
    oom.enable = true;
    theming.enable = true;
    appImages.enable = true;

    gnome = {
      inherit user;
      enable = true;
      additionalExtensions = [
        pkgs.draw-on-your-screen2
      ];
    };

    hyprland = {
      inherit user;
      enable = true;
      gnomeCompatibility = true;
    };

    github-runner = {
      enable = false;
      url = "https://github.com/FmTod";
      secrets.token = ../../secrets/github/runner.age;
    };

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

      paths = [
        "/persist/home/${user}/Development"
      ];

      home = {
        users = [user];
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
      inherit user;
      enable = true;
      directories = [
        "/etc/mullvad-vpn"
        "/etc/gdm"
      ];
      home = {
        share = [
          "JetBrains"
          "keyrings"
          "direnv"
          "zoxide"
          "mkcert"
          "pnpm"
          "nvim"
        ];
        config = [
          "Code"
          "Slack"
          "Insomnia"
          "JetBrains"
          "1Password"
          "Tinkerwell"
          "Mullvad VPN"
          "microsoft-edge"
          "github-copilot"
          "tinkerwell"
          "composer"
          "direnv"
          "op"
        ];
        cache = [
          "JetBrains"
        ];
        directories = [
          ".pki"
          ".ssh"
          ".zen"
          ".kube"
          ".java"
          ".gnupg"
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
    };
  };
}
