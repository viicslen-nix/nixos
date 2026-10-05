# Disk layouts, exposed as functions of their parameters (e.g. `{device}`).
{lib, ...}: let
  layoutsPath = ../disko;

  layouts =
    lib.mapAttrs'
    (file: _: lib.nameValuePair (lib.removeSuffix ".nix" file) (import (layoutsPath + "/${file}")))
    (lib.filterAttrs (file: type: type == "regular" && lib.hasSuffix ".nix" file) (builtins.readDir layoutsPath));
in {
  _module.args.diskoLayouts = layouts;

  flake.diskoLayouts = layouts;
}
