{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  ...
}:
with lib; let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_OPTIMUS=NVIDIA_only
    exec -a "$0" "$@"
  '';
in {
  imports = [
    ../work
    ./hardware.nix
    inputs.nixos-hardware.nixosModules.asus-zephyrus-gu603h
  ];

  boot = {
    kernelParams = [
      "video=eDP-1-1:2560x1600@165" # Patch for 165hz display
      "intel_iommu=on" # Hardware virtualisation
    ];
  };

  hardware = {
    opengl = {
      enable = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        libGL
      ];

      setLdLibraryPath = true;
    };

    nvidia = {
      modesetting.enable = true;
    };

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
      asusdConfig = ''        (
                bat_charge_limit: 80,
              )'';
    };

    tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0=75;
        STOP_CHARGE_THRESH_BAT0=90;

        CPU_BOOST_ON_AC=0;
        CPU_BOOST_ON_BAT=0;
        CPU_HWP_DYN_BOOST_ON_AC=0;
        CPU_HWP_DYN_BOOST_ON_BAT=0;
        CPU_SCALING_GOVERNOR_ON_BATTERY = "powersave";
      };
    };

    power-profiles-daemon.enable = false;
  };

  powerManagement.cpuFreqGovernor = "powersave";
  features.network.hostName = "asus-zephyrus-gu603";
}
