# Re-export viicslen-lib as `self.lib` so modules can reach it via
# `inputs.self.lib`.
{inputs, ...}: {
  flake.lib = inputs.viicslen-lib.lib;
}
