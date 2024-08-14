{
  disko.devices = {
    disk = {
      nix = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                ];
              };
            };
            os = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };
    zpool = {
      rpool = {
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^rpool/root@blank$' || zfs snapshot rpool/root@blank";
        datasets = {
          "root" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
          };
          "nix" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
          };
          "home" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/home";
          };
          "persist" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/persist";
          };
        };
      };
    };
  };
}
