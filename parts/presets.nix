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
  # Deliberately NOT under flake.nixosModules: that attrset is the pool of
  # feature modules every host imports, whereas presets are selected per host.
  _module.args.presetModules = presets;

  flake.presets = presets;
}
