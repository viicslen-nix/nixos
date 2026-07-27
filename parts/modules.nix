# Discovery and export of the reusable NixOS / home-manager module trees.
{inputs, ...}: let
  vlib = inputs.viicslen-lib.lib;

  # Raw trees as produced by autoImportRecursive: a nested attrset where a
  # category (e.g. `core`) maps to a set of modules.
  nixosModuleTree = vlib.modules.autoImportRecursive ../modules/nixos;
  homeModuleTree = vlib.modules.autoImportRecursive ../modules/home-manager;
in {
  # Share the raw trees with the other parts (see hosts.nix). They are kept out
  # of the typed `flake.nixosModules` option on purpose: flake-parts normalises
  # each entry into `{_class; _file; imports;}`, which breaks hosts.nix's
  # "an attrset value is a category of modules" convention.
  _module.args = {inherit nixosModuleTree homeModuleTree;};

  flake = {
    # Reusable nixos modules you might want to export
    nixosModules = nixosModuleTree;

    # Reusable home-manager modules you might want to export
    homeManagerModules = homeModuleTree;
  };
}
