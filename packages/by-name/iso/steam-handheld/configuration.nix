{
  pkgs,
  lib,
  ...
}: {
  imports = [
    inputs.chaotic.nixosModules.default
    inputs.jovian.nixosModules.default
  ];

  documentation = {
    enable = false;
    nixos.options.warningsAreErrors = false;
    info.enable = false;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_cachyos;
    supportedFilesystems = lib.mkForce ["btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs"];
  };

  networking = {
    firewall.enable = false;
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

  hardware.amdgpu.initrd.enable = false;
  jovian.hardware.has.amd.gpu = true;
}
