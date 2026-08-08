# Re-export the local packages from the `packages` subflake as this flake's own
# `packages.<system>.<name>`, so `nix build .#superset` works and CI can build
# and cache them. They are otherwise only reachable as `pkgs.inputs.packages.*`
# inside modules.
{inputs, ...}: {
  perSystem = {system, ...}: {
    packages = inputs.packages.packages.${system} or {};
  };
}
