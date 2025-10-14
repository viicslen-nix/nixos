{
  lib,
  pkgs,
  ...
}:
with lib; {
  system.stateVersion = "25.05";

  nix = {
    gc.automatic = true;

    settings = {
      auto-optimise-store = true;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    settings.experimental-features = ["nix-command" "flakes"];
    extraOptions = "experimental-features = nix-command flakes";
    nixPath = ["nixpkgs=${pkgs.path}"];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = lib.mkForce ["btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs"];
  };

  networking = {
    firewall.enable = false;
    wireless.enable = false;
    networkmanager = {
      enable = true;
      insertNameservers = [
        "1.1.1.1"
        "1.0.0.1"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
      ];
    };
  };

  systemd = {
    network = {
      enable = true;
      networks =
        mapAttrs'
        (num: _:
          nameValuePair "eth${num}" {
            extraConfig = ''
              [Match]
              Name = eth${num}
              [Network]
              DHCP = both
              LLMNR = true
              IPv4LL = true
              LLDP = true
              IPv6AcceptRA = true
              IPv6Token = ::521a:c5ff:fefe:65d9
              # used to have a stable address for zfs send
              Address = fd42:4492:6a6d:43:1::${num}/64
              [DHCP]
              UseHostname = false
              RouteMetric = 512
            '';
          })
        {
          "0" = {};
          "1" = {};
          "2" = {};
          "3" = {};
        };
    };

    services = {
      update-prefetch.enable = false;
      sshd.wantedBy = mkForce ["multi-user.target"];
    };

    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };

  services = {
    qemuGuest.enable = true;
    resolved.enable = false;
    openssh.settings.PermitRootLogin = lib.mkForce "yes";

    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };
  };

  environment = {
    # Use helix as the default editor
    variables.EDITOR = "hx";

    systemPackages = with pkgs; let
      gitBin = getExe git;
      gumBin = getExe gum;
      gsettingsBin = getExe' glib "gsettings";
    in [
      helix
      vim
      curl
      wget
      httpie
      diskrsync
      partclone
      ntfsprogs
      ntfs3g
      networkmanager
      git
      (writeShellScriptBin "disko-install" ''
        #!/usr/bin/env bash

        set -euo pipefail

        ${gsettingsBin} set org.gnome.desktop.session idle-delay 0
        ${gsettingsBin} set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

        if [ "$(id -u)" -eq 0 ]; then
          echo "ERROR! $(basename "$0") should be run as a regular user"
          exit 1
        fi

        if [ ! -d "$HOME/nixos/.git" ]; then
          ${gitBin} clone https://github.com/viicslen/nixos.git "$HOME/nixos"
        fi

        TARGET_HOST=$(ls -1 ~/nixos/hosts/*/default.nix | cut -d'/' -f6 | grep -v iso | ${gumBin} choose)

        if [ ! -e "$HOME/nixos/hosts/$TARGET_HOST/disko.nix" ]; then
          echo "ERROR! $(basename "$0") could not find the required $HOME/nixos/hosts/$TARGET_HOST/disko.nix"
          exit 1
        fi

        TARGET_DISK=$(lsblk -o NAME,SIZE,TYPE,TRAN,MODEL | grep disk | ${gumBin} choose | awk '{print $1}')

        ${gumBin} confirm  --default=false \
        "🔥 🔥 🔥 WARNING!!!! This will ERASE ALL DATA on the disk $TARGET_HOST. Are you sure you want to continue?"

        echo "Partitioning Disks"
        sudo nix run github:nix-community/disko \
        --extra-experimental-features "nix-command flakes" \
        --no-write-lock-file \
        -- \
        --mode disko \
        "$HOME/nixos/hosts/$TARGET_HOST/disko.nix" \
        --arg device '"/dev/$TARGET_DISK"'

        sudo nixos-install --flake "$HOME/nixos#$TARGET_HOST"
      '')
    ];
  };

  programs.direnv.enable = true;

  documentation = {
    enable = false;
    nixos.options.warningsAreErrors = false;
    info.enable = false;
  };
}
