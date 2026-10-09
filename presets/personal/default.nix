{
  lib,
  users,
  config,
  nixosModules,
  ...
}:
with lib; let
  desktop = config.modules.presets.desktop.enable;
in {
  imports = [
    nixosModules.containers.homarr
    nixosModules.programs.qmk
  ];

  config = {
    home-manager.sharedModules = [./home.nix];

    users.users = mapAttrs (_: _: {extraGroups = ["adbusers"];}) users;

    modules = {
      programs.qmk.enable = desktop;
      containers.homarr.enable = desktop;
    };

    # Optimization: Prevent systemd from waiting for network online
    # (Optional but recommended for faster boot with VPNs)
    systemd.network.wait-online.enable = false;
    boot.initrd.systemd.network.wait-online.enable = false;

    services = {
      dictd.enable = mkDefault true;
    };

    programs = {
      localsend.enable = mkDefault desktop;
    };
  };
}
