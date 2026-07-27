# NixOS configurations for all hosts.
#
# The host list, and the presets each host receives, are declared in
# ../hosts/default.nix. Hosts and presets reach the registered modules through
# the `nixosModules` / `homeModules` specialArgs, e.g.
#
#   {nixosModules, ...}: { imports = with nixosModules; [docker steam]; }
{
  inputs,
  lib,
  config,
  presetModules,
  ...
}: let
  hostsPath = ../hosts;
  hostsConfig = import hostsPath {};
  shared = hostsConfig.shared or {};
  hosts = hostsConfig.hosts or {};

  nixosModules = config.flake.nixosModules;
  homeModules = config.flake.homeManagerModules;

  # home-manager's own modules are only wired up when the host actually pulls in
  # home-manager (the base preset does), hence the option guard.
  hmSharedModules = {options, ...}: {
    config = lib.mkIf (builtins.hasAttr "home-manager" options) {
      home-manager.sharedModules = lib.attrValues homeModules;
    };
  };

  mkHost = hostName: hostConfig:
    inputs.nixpkgs.lib.nixosSystem {
      modules =
        (shared.modules or [])
        ++ lib.attrValues nixosModules
        ++ [hmSharedModules]
        ++ map (name: presetModules.${name}) (hostConfig.presets or [])
        ++ [
          (hostConfig.path or (hostsPath + "/${hostName}"))
          {nixpkgs.hostPlatform.system = hostConfig.system;}
        ];

      specialArgs = {
        inherit inputs hostName nixosModules homeModules;
        outputs = inputs.self.outputs;
        users = shared.users or {};
      };
    };
in {
  flake.nixosConfigurations = lib.mapAttrs mkHost hosts;
}
