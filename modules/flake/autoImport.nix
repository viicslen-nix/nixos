# The importApply argument. Use this to reference things defined locally,
# as opposed to the flake where this is imported.
localFlake:

# Regular module arguments; self, inputs, etc all reference the final user flake,
# where this module was imported.
{ lib, config, self, inputs, ... }:
{
  perSystem = { system, ... }: {
    easyHosts.shared.specialArgs.ylib = inputs.nypkgs.lib.${system};
  };
}
