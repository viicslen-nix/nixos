# Which systems the per-system outputs (packages, devShells, formatter) are
# generated for. Sourced from viicslen-lib so it stays in step with the helpers
# that used to build these outputs by hand.
{inputs, ...}: {
  systems = inputs.viicslen-lib.lib.defaultSystems;
}
