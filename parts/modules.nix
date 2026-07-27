# Module discovery.
#
# Every `default.nix` under ../modules/{nixos,home-manager} is itself a
# flake-parts module registering one entry under `flake.nixosModules.<name>` or
# `flake.homeManagerModules.<name>`, named after its directory. Adding a module
# is just adding a file, at any depth.
#
# flake-parts types `flake.nixosModules` as `lazyAttrsOf deferredModule` and
# wraps each *top-level* entry in `{_class; _file; imports;}`, so that attrset
# has to stay flat. To keep the directory namespaces at import sites we build a
# nested view over it and hand that to hosts as the `nixosModules` /
# `homeModules` specialArgs:
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
{
  lib,
  config,
  ...
}: let
  discover = root:
    builtins.filter (
      p: let
        s = toString p;
      in
        lib.hasSuffix "/default.nix" s && !(lib.hasInfix "/_" s)
    ) (lib.filesystem.listFilesRecursive root);

  # ["hardware" "nvidia"] for modules/nixos/hardware/nvidia/default.nix
  segmentsOf = root: p:
    lib.init (lib.splitString "/" (lib.removePrefix (toString root + "/") (toString p)));

  # Build the nested view, mapping each directory path onto its flat registry
  # entry (registry entries are keyed by the directory's base name).
  mkTree = root: registry: let
    files = discover root;
    allSegments = map (segmentsOf root) files;
    isNamespace = segs:
      lib.any
      (other: lib.length other > lib.length segs && lib.take (lib.length segs) other == segs)
      allSegments;
    keyFor = segs:
      if isNamespace segs
      then segs ++ ["base"]
      else segs;
  in
    lib.foldl' (
      acc: p: let
        segs = segmentsOf root p;
      in
        lib.recursiveUpdate acc
        (lib.setAttrByPath (keyFor segs) registry.${lib.last segs})
    ) {}
    files;

  # The flat registry keys off directory base names, so those must be unique
  # within a tree. Fail loudly rather than let one registration silently
  # clobber another.
  assertUnique = root: let
    names = map (p: lib.last (segmentsOf root p)) (discover root);
    dupes = lib.subtractLists (lib.unique names) names;
  in
    if dupes == []
    then true
    else throw "Duplicate module directory names under ${toString root}: ${lib.concatStringsSep ", " (lib.unique dupes)}";

  nixosTree =
    assert assertUnique ../modules/nixos;
      mkTree ../modules/nixos config.flake.nixosModules;
  homeTree =
    assert assertUnique ../modules/home-manager;
      mkTree ../modules/home-manager config.flake.homeManagerModules;
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
