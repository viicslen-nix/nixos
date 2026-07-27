# Module discovery.
#
# Every `default.nix` under ../modules/{nixos,home-manager} is itself a
# flake-parts module that registers one entry under `flake.nixosModules.<name>`
# or `flake.homeManagerModules.<name>`, named after its directory. They are
# imported here, so adding a module is just adding a file — at any depth.
#
# Convention: a path component starting with `_` is skipped, for helpers that
# are not modules (e.g. services/impermanence/_presets, whose default.nix takes
# a `systemConfig` argument).
{lib, ...}: let
  discover = root:
    builtins.filter (
      p: let
        s = toString p;
      in
        lib.hasSuffix "/default.nix" s && !(lib.hasInfix "/_" s)
    ) (lib.filesystem.listFilesRecursive root);
in {
  imports = discover ../modules/nixos ++ discover ../modules/home-manager;
}
