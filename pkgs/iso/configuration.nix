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

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = lib.mkForce ["btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs"];
  };

  networking = {
    firewall.enable = false;
    useNetworkd = true;
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
    usePredictableInterfaceNames = false;
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
  };

  environment = {
    # Use helix as the default editor
    variables.EDITOR = "hx";

    systemPackages = with pkgs; [
      helix
      vim
      curl
      wget
      httpie
      diskrsync
      partclone
      ntfsprogs
      ntfs3g
      git
      gum
      (writeShellScriptBin "disko-install" ''
        #!/usr/bin/env bash

        set -euo pipefail

        gsettings set org.gnome.desktop.session idle-delay 0
        gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

        if [ "$(id -u)" -eq 0 ]; then
          echo "ERROR! $(basename "$0") should be run as a regular user"
          exit 1
        fi

        if [ ! -d "$HOME/nixos/.git" ]; then
          git clone https://github.com/viicslen/nixos.git "$HOME/nixos"
        fi

        TARGET_HOST=$(ls -1 ~/nixos/hosts/*/default.nix | cut -d'/' -f6 | grep -v iso | gum choose)

        if [ ! -e "$HOME/nixos/hosts/$TARGET_HOST/disko.nix" ]; then
          echo "ERROR! $(basename "$0") could not find the required $HOME/nixos/hosts/$TARGET_HOST/disko.nix"
          exit 1
        fi

        TARGET_DISK=$(lsblk -o NAME,SIZE,TYPE,TRAN,MODEL | grep disk | gum choose | awk '{print $1}')

        gum confirm  --default=false \
        "🔥 🔥 🔥 WARNING!!!! This will ERASE ALL DATA on the disk $TARGET_HOST. Are you sure you want to continue?"

        echo "Partitioning Disks"
        sudo nix run github:nix-community/disko \
        --extra-experimental-features "nix-command flakes" \
        --no-write-lock-file \
        -- \
        --mode disko \
        "$HOME/nixos/hosts/$TARGET_HOST/disko.nix" \
        --arg device '"/dev/''${TARGET_DISK}"'

        sudo nixos-install --flake "$HOME/nixos#$TARGET_HOST"
      '')
    ];
  };

  documentation = {
    enable = false;
    nixos.options.warningsAreErrors = false;
    info.enable = false;
  };
}
