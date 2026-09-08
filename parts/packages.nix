# Re-export the local packages from the `packages` subflake as this flake's own.
{inputs, ...}: {
  perSystem = {system, ...}: {
    packages = inputs.packages.packages.${system} or {};
  };
}
