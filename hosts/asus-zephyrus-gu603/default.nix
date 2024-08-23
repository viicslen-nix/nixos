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
    inputs.impermanence.nixosModules.impermanence
    inputs.disko.nixosModules.disko
    (import ./disko.nix {device = "/dev/nvme0n1";})
    ./hardware.nix
    ../../base/nixos
    ../../base/personal
    ../../base/work
  ];

  fileSystems."/persist".neededForBoot = true;
  powerManagement.cpuFreqGovernor = "powersave";
  networking.hostId = "86f2c355";

  boot = {
    kernelParams = [
      "video=eDP-1-1:2560x1600@165" # Patch for 165hz display
      "intel_iommu=on" # Hardware virtualisation
      "nvidia_drm.fbdev=1" # Nvidia DRM
    ];

    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false;

    initrd.postDeviceCommands = lib.mkAfter ''
      mkdir /btrfs_tmp
      mount /dev/root_vg/root /btrfs_tmp
      if [[ -e /btrfs_tmp/root ]]; then
          mkdir -p /btrfs_tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
          mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
      fi

      delete_subvolume_recursively() {
          IFS=$'\n'
          for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
              delete_subvolume_recursively "/btrfs_tmp/$i"
          done
          btrfs subvolume delete "$1"
      }

      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
          delete_subvolume_recursively "$i"
      done

      btrfs subvolume create /btrfs_tmp/root
      umount /btrfs_tmp
    '';
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

  services = {
    xserver = {
      enable = true;

      exportConfiguration = true;
      displayManager.sessionCommands = ''
        xrandr --newmode "2560x1600_165.00" 1047.00 2560 2800 3080 3600  1600 1603 1609 1763 -hsync +vsync
        xrandr --addmode eDP-1-1 "2560x1600_165.00"
        xrandr --output eDP-1-1 --mode 2560x1600 --rate 165
      '';

      videoDrivers = [ "nvidia" ];
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

  environment = {
    systemPackages = with pkgs; [
      asusctl
      supergfxctl
      zenith-nvidia
      nvtopPackages.nvidia
      gnomeExtensions.supergfxctl-gex
    ];

    persistence."/persist/system" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/docker"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/etc/NetworkManager/system-connections"
        "/etc/nixos"
        { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
      ];
      files = [
        "/etc/machine-id"
        # { file = "/var/keys/secret_file"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
      ];
    };
  };

  features = {
    network.hostName = "asus-zephyrus-gu603";

    oom.enable = true;
    theming.enable = true;
    appImages.enable = true;

    gnome = {
      enable = true;
      inherit user;
    };
  };

  home-manager.users.${user} = import ./home.nix;

  programs.fuse.userAllowOther = true;
}
