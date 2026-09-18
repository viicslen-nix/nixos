{
  inputs,
  pkgs,
  lib,
  nixosModules,
  ...
}:
with lib; {
  imports = [
    inputs.jovian.nixosModules.default
    ./hardware.nix

    nixosModules.containers.base
    nixosModules.programs.docker
  ];

  ####################
  # Boot & Kernel    #
  ####################
  boot = {
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

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
      efi.canTouchEfiVariables = true;
      grub.configurationLimit = 5;
    };

    consoleLogLevel = 0;
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
  };

  #################
  # Hardware      #
  #################
  hardware = {
    enableAllFirmware = true;
    amdgpu.initrd.enable = false;
    bluetooth.settings.General.MultiProfile = "multiple";
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
    docker.enableOnBoot = false;
    libvirtd.enable = true;
  };

  ########################
  # Programs & Services  #
  ########################
  environment = {
    sessionVariables = {
      PROTON_USE_NTSYNC = "1";
      ENABLE_HDR_WSI = "1";
      DXVK_HDR = "1";
      PROTON_ENABLE_AMD_AGS = "1";
      PROTON_ENABLE_NVAPI = "1";
      ENABLE_GAMESCOPE_WSI = "1";
      STEAM_MULTIPLE_XWAYLANDS = "1";
    };
    systemPackages = with pkgs; [
      wvkbd
      maliit-keyboard
      maliit-framework
      kdePackages.qtvirtualkeyboard
      protonplus
    ];
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

  programs = {
    vscode = {
      enable = true;
      defaultEditor = true;
      package = pkgs.vscode-fhs;
    };
  };

  modules = {
    containers.settings.backend = "docker";

    # Jovian/SteamOS manages its own OOM handling, so opt out of the desktop
    # preset's default.
    services.oom.enable = false;
    # Jovian ships its own bluetooth config; the module's "true" string clashes with its bool.
    hardware.bluetooth.enable = false;
  };

  ########################
  # Graphical & Jovian   #
  ########################
  jovian = {
    hardware.has.amd.gpu = true;
    steam = {
      enable = true;
      autoStart = true;
      user = "neoscode";
      desktopSession = "plasma";
    };
    decky-loader = {
      enable = true;
      user = "neoscode";
    };
    steamos = {
      useSteamOSConfig = true;
    };
    devices.steamdeck = {
      enableDefaultCmdlineConfig = false;
      enable = true;
      enableOsFanControl = false;
      enableFwupdBiosUpdates = false;
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
