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
    ./hardware.nix
    ../../base/nixos
    ../../base/personal
    ../../base/work
  ];

  boot = {
    kernelParams = [
      "video=eDP-1-1:2560x1600@165" # Patch for 165hz display
      "intel_iommu=on" # Hardware virtualisation
    ];

    loader.systemd-boot.enable = true;
    loader.systemd-boot.configurationLimit = 10;
    loader.efi.canTouchEfiVariables = false;

    plymouth.enable = true;
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        libGL
      ];
    };

    nvidia.modesetting.enable = true;
    logitech.wireless.enable = true;
  };

  environment.systemPackages = with pkgs; [
    asusctl
    supergfxctl
    zenith-nvidia
    nvtopPackages.nvidia
  ];

  services = {
    xserver = {
      enable = true;

      xkb = {
        layout = "us";
        variant = "";
      };

      exportConfiguration = true;
      displayManager.sessionCommands = ''
        xrandr --newmode "2560x1600_165.00" 1047.00 2560 2800 3080 3600  1600 1603 1609 1763 -hsync +vsync
        xrandr --addmode eDP-1-1 "2560x1600_165.00"
        xrandr --output eDP-1-1 --mode 2560x1600 --rate 165
      '';
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

    printing.enable = true;
    power-profiles-daemon.enable = false;
  };

  powerManagement.cpuFreqGovernor = "powersave";

  features = {
    network.hostName = "asus-zephyrus-gu603";

    gnome = {
      enable = true;
      enableGdm = false;
      inherit user;
    };

    kde = {
      enable = true;
      enableSddm = true;
    };

    hyprland = {
      enable = true;
      inherit user;
    };

    oom.enable = true;
    theming.enable = true;
    appImages.enable = true;
  };

  programs.ssh.askPassword = mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";

  home-manager.backupFileExtension = "backup";
}
