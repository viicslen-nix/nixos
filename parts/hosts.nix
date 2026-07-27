# NixOS configurations for all hosts.
#
# The host list, and the presets each host receives, are declared in
# ../hosts/default.nix. Every host gets the full module set; individual modules
# are switched on through their `modules.<namespace>.<name>.enable` options.
{
  inputs,
  lib,
  nixosModuleList,
  homeModuleList,
  ...
}: let
  hostsPath = ../hosts;
  hostsConfig = import hostsPath {};
  shared = hostsConfig.shared or {};
  hosts = hostsConfig.hosts or {};

  presetsPath = hostsPath + "/_shared/presets";

  # home-manager's own modules are only wired up when the host actually pulls in
  # home-manager (the base preset does), hence the option guard.
  hmSharedModules = {options, ...}: {
    config = lib.mkIf (builtins.hasAttr "home-manager" options) {
      home-manager.sharedModules = homeModuleList;
    };
  };

  mkHost = hostName: hostConfig:
    inputs.nixpkgs.lib.nixosSystem {
      modules =
        (shared.modules or [])
        ++ nixosModuleList
        ++ [hmSharedModules]
        ++ map (name: presetsPath + "/${name}") (hostConfig.presets or [])
        ++ [
          (hostConfig.path or (hostsPath + "/${hostName}"))
          {nixpkgs.hostPlatform.system = hostConfig.system;}
        ];

      specialArgs = {
        inherit inputs hostName;
        outputs = inputs.self.outputs;
        users = shared.users or {};
      };
    };
in {
  flake.nixosConfigurations = lib.mapAttrs mkHost hosts;
}
