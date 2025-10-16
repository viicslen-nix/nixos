{
  inputs,
  config,
  users,
  pkgs,
  lib,
  ...
}: with lib; {
  imports = [
    inputs.chaotic.nixosModules.default
    inputs.jovian.nixosModules.default
    ./hardware.nix
  ];

  ####################
  # Boot & Kernel    #
  ####################
  boot = {
    kernelPackages = pkgs.linuxPackages_cachyos;

    # kernelParams = ["quiet"];
    # kernel.sysctl = {
    #   "kernel.split_lock_mitigate" = 0;
    #   "kernel.nmi_watchdog" = 0;
    #   "kernel.sched_bore" = "1";
    # };

    # initrd = {
    #   systemd.enable = true;
    #   verbose = false;
    # };

    loader = {
      timeout = 0;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
      grub = {
        device = "nodev";
        efiSupport = true;
        configurationLimit = 5;
      };
      systemd-boot.enable = false;
    };

    consoleLogLevel = 0;
    plymouth.enable = true;
  };

  systemd.settings.Manager = {DefaultTimeoutStopSec = "5s";};

  ################
  # FileSystems  #
  ################
  # fileSystems."/" = {
  #   options = ["compress=zstd"];
  # };

  zramSwap = {
    enable = false;
    algorithm = "zstd";
  };

  ############
  # Network  #
  ############
  networking = {
    hostName = "lenovo-legion-go";
    firewall.enable = false;
  };

  #################
  # Hardware      #
  #################
  hardware = {
    enableAllFirmware = true;
    amdgpu.initrd.enable = false;
    bluetooth = {
      enable = true;
      settings = {
        General = {
          MultiProfile = "multiple";
          FastConnectable = true;
        };
      };
    };
  };

  #################
  # Security      #
  #################
  security = {
    polkit.enable = true;
    sudo.wheelNeedsPassword = false;
  };

  ###################
  # Virtualization  #
  ###################
  virtualisation = {
    docker.enable = true;
    docker.enableOnBoot = false;
    libvirtd.enable = true;
  };

  ########################
  # Programs & Services  #
  ########################
  environment.sessionVariables = {
    PROTON_USE_NTSYNC = "1";
    ENABLE_HDR_WSI = "1";
    DXVK_HDR = "1";
    PROTON_ENABLE_AMD_AGS = "1";
    PROTON_ENABLE_NVAPI = "1";
    ENABLE_GAMESCOPE_WSI = "1";
    STEAM_MULTIPLE_XWAYLANDS = "1";
  };

  services = {
    seatd.enable = true;
    openssh.enable = true;
    flatpak.enable = true;
    desktopManager.plasma6.enable = true;
    handheld-daemon = {
      enable = true;
      user = "neoscode";
      ui.enable = true;
    };
  };

  modules = {
    presets.base.enable = true;

    functionality = {
      theming.enable = true;
      appImages.enable = true;
    };

    programs = {
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

  ########################
  # Graphical & Jovian   #
  ########################
  jovian = {
    steam = {
      enable = true;
      autoStart = true;
      user = "neoscode";
      desktopSession = "plasma";
    };
    decky-loader.enable = true;
    hardware.has.amd.gpu = true;
    devices.steamdeck = {
      enable = true;
      enableOsFanControl = false;
#       enableControllerUdevRules = true;
      enableFwupdBiosUpdates = false;
      enableDefaultCmdlineConfig = false;
#       enableGyroDsuService = true;
#       enableKernelPatches = true;
    };
    steamos = {
      useSteamOSConfig = true;
      enableEarlyOOM = false;
    };
  };

  ###############
  # Users       #
  ###############
  users.users.neoscode.extraGroups = [
    "docker"
    "video"
    "seat"
    "audio"
    "libvirtd"
  ];
}
