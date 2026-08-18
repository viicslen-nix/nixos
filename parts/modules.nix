# Module discovery.
#
# Every `default.nix` under ../modules/{nixos,home-manager} is itself a
# flake-parts module registering one entry under `flake.modules.nixos.<name>` or
# `flake.modules.homeManager.<name>` (the native dendritic output, enabled in
# flake-modules.nix), named after its directory. Adding a module is just adding
# a file, at any depth.
#
# `flake.modules.<class>` is flat within a class. To keep the directory
# namespaces at import sites we build a nested view over it and hand that to
# hosts as the `nixosModules` / `homeModules` specialArgs:
#
#   imports = with nixosModules; [hardware.nvidia programs.docker];
#
# A directory that is both a module and a namespace (containers/default.nix,
# which declares the settings its children read) is reachable as
# `<namespace>.base`.
#
# Convention: a path component starting with `_` is skipped, for helpers that
# are not modules (e.g. services/impermanence/_presets, whose default.nix takes
# a `systemConfig` argument).
#
# The walk itself lives in the lib subflake (`discovery.nix`) — it is pure
# path-and-attrset work, parameterised by the root and the registry.
{
  inputs,
  config,
  ...
}: let
  inherit (inputs.viicslen-lib.lib.discovery) discover mkTree assertUnique;

  nixosTree = assert assertUnique ../modules/nixos;
    mkTree ../modules/nixos config.flake.modules.nixos;
  homeTree = assert assertUnique ../modules/home-manager;
    mkTree ../modules/home-manager config.flake.modules.homeManager;
in {
  imports = discover ../modules/nixos ++ discover ../modules/home-manager;

  _module.args = {
    nixosModules = nixosTree;
    homeModules = homeTree;
  };

  # Namespaced view, also exported for anything consuming this flake.
  flake.moduleTree = {
    nixos = nixosTree;
    homeManager = homeTree;
  };
}
