# Module discovery.
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
