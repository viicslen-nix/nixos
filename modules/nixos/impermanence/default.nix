{
  lib,
  pkgs,
  config,
  inputs,
  options,
  ...
}:
with lib; let
  name = "impermanence";
  namespace = "features";

  cfg = config.${namespace}.${name};
  homeManagerLoaded = builtins.hasAttr "home-manager" options;
in {
  options.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "impermanence");
    persistencePath = mkOption {
      type = types.str;
      default = "/persist";
      description = "Root path where to store persistent files and directories";
    };
    resetBtrfsRoot = mkOption {
      type = types.bool;
      default = true;
      description = "Reset root filesystem";
    };
    user = mkOption {
      type = types.str;
      default = "nixos";
      description = "The user to use in the impermanence home path";
    };
    directories = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Directories to keep after reboot";
    };
    files = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Files to keep after reboot";
    };
    home = {
      share = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Share directories to keep after reboot";
      };
      config = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Config directories to keep after reboot";
      };
      cache = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Cache directories to keep after reboot";
      };
      directories = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Directories to keep after reboot";
      };
      files = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Files to keep after reboot";
      };
    };
  };

  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  config = mkIf cfg.enable {
    boot.initrd.postDeviceCommands = mkIf cfg.resetBtrfsRoot (mkAfter ''
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
    '');

    programs.fuse.userAllowOther = true;

    fileSystems.${cfg.persistencePath}.neededForBoot = true;

    environment.systemPackages = with pkgs; [
      (pkgs.writeShellScriptBin "persist" ''
        if [[ -e "$1" ]]; then
            cp -a "$1" "${cfg.persistencePath}/$(realpath --relative-to="/" "$1")"
        else
            echo "Error: $1 does not exist"
            exit 1
        fi
      '')
    ];

    environment.persistence."${cfg.persistencePath}/system" = {
      hideMounts = true;
      directories =
        [
          "/var/log"
          "/var/lib/docker"
          "/var/lib/bluetooth"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/etc/NetworkManager/system-connections"
          "/etc/nixos"
          {
            directory = "/var/lib/colord";
            user = "colord";
            group = "colord";
            mode = "u=rwx,g=rx,o=";
          }
        ]
        ++ cfg.directories;
      files =
        [
          "/etc/machine-id"
        ]
        ++ cfg.files;
    };

    home-manager.users.${cfg.user} = mkIf homeManagerLoaded {
      imports = [
        inputs.impermanence.nixosModules.home-manager.impermanence
      ];

      home.persistence."${cfg.persistencePath}/home/${cfg.user}" = {
        directories = concatLists [
          (lists.forEach cfg.home.share (dir: ".local/share/${dir}"))
          (lists.forEach cfg.home.config (dir: ".config/${dir}"))
          (lists.forEach cfg.home.cache (dir: ".cache/${dir}"))
          cfg.home.directories
          [
            {
              directory = "Development";
              method = "symlink";
            }
            {
              directory = ".nix";
              method = "symlink";
            }
            "Documents"
            "Downloads"
            "Pictures"
            "Desktop"
            "Videos"
            "Music"
          ]
        ];

        files = [] ++ cfg.home.files;

        allowOther = true;
      };
    };
  };
}
