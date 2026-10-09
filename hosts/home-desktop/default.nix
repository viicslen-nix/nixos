{
  lib,
  pkgs,
  inputs,
  nixosModules,
  diskoLayouts,
  ...
}:
with lib; {
  imports = [
    inputs.disko.nixosModules.disko
    (diskoLayouts.btrfs-lvm {device = "/dev/disk/by-uuid/2da72401-b2b8-4a0d-8324-fd474124f51e";})
    ./hardware.nix

    nixosModules.hardware.intel
    nixosModules.hardware.nvidia
    nixosModules.hardware.razer
    nixosModules.functionality.gaming
  ];

  services = {
    displayManager.defaultSession = "niri";
    udev.packages = [pkgs.platformio-core.udev];
    tailscale = {
      enable = true;
      openFirewall = true;
      extraUpFlags = ["--ssh"];
    };
  };

  boot = {
    binfmt.emulatedSystems = ["aarch64-linux"];
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

    loader.efi.canTouchEfiVariables = false;
  };

  networking = {
    hostId = "86f2c355";
    hostName = "home-desktop";
  };

  users.users.neoscode.extraGroups = ["dialout"];

  modules = {
    hardware.nvidia.latest = true;

    desktop = {
      niri.enable = true;
      hyprland.enable = true;
    };

    containers.settings = {
      backend = "podman";
      userns = "auto";
      storageDriver = "btrfs";
    };
  };
}
