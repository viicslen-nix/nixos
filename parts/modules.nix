# Module discovery.
{
  inputs,
  config,
  lib,
  ...
}: let
  inherit (inputs.viicslen-lib.lib.discovery) discover mkTree assertUnique;

  # Without a `key` the module system cannot dedupe a module two presets both import.
  withKeys = kind: lib.mapAttrs (name: m: {key = "${kind}:${name}"; imports = [m];});

  nixosTree = assert assertUnique ../modules/nixos;
    mkTree ../modules/nixos (withKeys "nixos" config.flake.modules.nixos);
  homeTree = assert assertUnique ../modules/home-manager;
    mkTree ../modules/home-manager (withKeys "homeManager" config.flake.modules.homeManager);
in {
  # A path component starting with `_` is skipped — that is how a non-module helper opts out.
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
