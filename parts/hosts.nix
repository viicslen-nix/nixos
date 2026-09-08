# NixOS configurations for all hosts.
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

  # This is what puts the option helpers in every module's ordinary `lib` — don't drop it.
  extendedLib = lib.extend (_final: _prev: inputs.viicslen-lib.lib.options);

  mkHost = hostName: hostConfig:
    inputs.nixpkgs.lib.nixosSystem {
      lib = extendedLib;

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
