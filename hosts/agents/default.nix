{
  lib,
  modulesPath,
  nixosModules,
  ...
}: let
  # git+https, not github: — the tarball fetcher drops the submodules every path: input needs.
  flake = "git+https://github.com/viicslen-nix/nixos";
in {
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
    nixosModules.services.netbird
  ];

  proxmoxLXC.manageHostName = true;

  networking = {
    hostName = "agents";
    # proxmox-lxc hands the interface to networkd; NetworkManager would fight it.
    networkmanager.enable = lib.mkForce false;
  };

  services.tailscale = {
    enable = true;
    extraUpFlags = ["--ssh"];
  };

  # The T3 Code server is a user unit; it must run with nobody logged in.
  users.users.neoscode.linger = true;

  programs.nh.flake = flake;
  environment.sessionVariables.NH_FLAKE = flake;

  system.autoUpgrade = {
    enable = true;
    flake = "${flake}#agents";
    flags = ["--refresh"];
    dates = "04:00";
    allowReboot = false;
  };
}
