{
  lib,
  pkgs,
  inputs,
  nixosModules,
  ...
}:
with lib; {
  imports = [
    inputs.disko.nixosModules.disko
    (import ../_shared/disko/btrfs-lvm.nix {device = "/dev/disk/by-uuid/2da72401-b2b8-4a0d-8324-fd474124f51e";})
    ./hardware.nix

    nixosModules.hardware.intel
    nixosModules.hardware.nvidia
    nixosModules.hardware.razer
    nixosModules.functionality.gaming
  ];

  home-manager.sharedModules = [./home.nix];

  services.displayManager.defaultSession = "niri";

  boot = {
    binfmt.emulatedSystems = ["aarch64-linux"];
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

    loader.efi.canTouchEfiVariables = false;
  };

  networking = {
    hostId = "86f2c355";
    hostName = "home-desktop";
  };

  environment.systemPackages = with pkgs; [
    rpi-imager
    orca-slicer
    platformio
  ];

  users.users.neoscode.extraGroups = ["dialout"];
  services.udev.packages = [pkgs.platformio-core.udev];

  services.tailscale = {
    enable = true;
    openFirewall = true;
    extraUpFlags = ["--ssh"];
  };

  modules = {
    hardware.nvidia.latest = true;

    desktop = {
      niri.enable = true;
      hyprland.enable = true;
    };

    containers.settings.storageDriver = "btrfs";
  };
}
