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
  presetModules,
  # Namespaced module trees, mirroring the modules/ directory layout
  # (see parts/modules.nix).
  nixosModules,
  homeModules,
  ...
}: let
  hostsPath = ../hosts;
  hostsConfig = import hostsPath {};
  shared = hostsConfig.shared or {};
  hosts = hostsConfig.hosts or {};

  mkHost = hostName: hostConfig:
    inputs.nixpkgs.lib.nixosSystem {
      # No blanket module import: presets and hosts pull in exactly the modules
      # they want, via the `nixosModules` / `homeModules` specialArgs.
      modules =
        (shared.modules or [])
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
