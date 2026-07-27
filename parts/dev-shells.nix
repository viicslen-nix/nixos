# Formatter and dev shells, per system.
#
# These deliberately build pkgs via `vlib.pkgsFor` rather than flake-parts'
# `perSystem.pkgs`, so the outputs stay identical to the pre-flake-parts layout
# (allowUnfree, no extra overlays).
{inputs, ...}: let
  vlib = inputs.viicslen-lib.lib;
in {
  perSystem = {system, ...}: {
    # Formatter for your nix files, available through 'nix fmt'
    formatter = (vlib.pkgsFor system).alejandra;

    devShells = import ../dev-shells {
      inherit inputs system;
      pkgs = vlib.pkgsFor system;
    };
  };
}
