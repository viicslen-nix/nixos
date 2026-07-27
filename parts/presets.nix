# Presets, exposed as named, composable NixOS modules.
#
# A preset is a bundle of configuration in ../hosts/_shared/presets/<name>.
# Hosts opt in through their `presets = [ … ]` list in ../hosts/default.nix;
# publishing them here also makes them reachable as
# `self.nixosModules.presets.<name>` from outside the flake.
{lib, ...}: let
  presetsPath = ../hosts/_shared/presets;

  names =
    builtins.attrNames
    (lib.filterAttrs (_: type: type == "directory") (builtins.readDir presetsPath));

  presets = lib.genAttrs names (name: presetsPath + "/${name}");
in {
  _module.args.presetModules = presets;

  flake.nixosModules.presets = presets;
}
