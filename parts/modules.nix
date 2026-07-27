# Discovery and export of the reusable NixOS / home-manager modules.
#
# Every `default.nix` under ../modules/{nixos,home-manager} is a module and is
# picked up automatically, at any nesting depth. This replaces vlib's
# `autoImportRecursive`, which could not descend into a directory that had both
# a `default.nix` and subdirectories — that limitation is why
# modules/nixos/containers/default.nix used to hand-maintain a list of its 14
# children.
#
# Convention: a path component starting with `_` is skipped, for helper files
# that are not modules — e.g. services/impermanence/_presets, whose default.nix
# takes a `systemConfig` argument and so is not a NixOS module.
{lib, ...}: let
  discover = root:
    builtins.filter (
      p: let
        s = toString p;
      in
        lib.hasSuffix "/default.nix" s && !(lib.hasInfix "/_" s)
    ) (lib.filesystem.listFilesRecursive root);

  nixosModuleList = discover ../modules/nixos;
  homeModuleList = discover ../modules/home-manager;
in {
  # Shared with parts/hosts.nix.
  _module.args = {inherit nixosModuleList homeModuleList;};

  flake = {
    # Every module, bundled as one importable module. Consumers get the whole
    # set and switch individual modules on through their
    # `modules.<namespace>.<name>.enable` options.
    nixosModules.default = {imports = nixosModuleList;};
    homeManagerModules.default = {imports = homeModuleList;};
  };
}
