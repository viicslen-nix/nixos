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

  # Every module reaches the repo-wide option helpers through its ordinary `lib`
  # argument, rather than each one importing them. home-manager derives its own
  # `extendedLib` from the lib it is handed (nixos/common.nix), so this covers
  # home-manager modules too.
  #
  # Caveat: modules exported via `flake.modules.*` now assume this extension. An
  # outside consumer importing them must extend their lib the same way, or reach
  # the helpers directly at `inputs.viicslen-lib.lib.options`.
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
