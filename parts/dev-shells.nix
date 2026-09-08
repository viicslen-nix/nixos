# Dev shells, per system.
{inputs, ...}: let
  vlib = inputs.viicslen-lib.lib;
in {
  perSystem = {
    config,
    system,
    ...
  }: {
    devShells =
      builtins.mapAttrs (
        _: shell:
          shell.overrideAttrs (old: {
            shellHook = (old.shellHook or "") + config.pre-commit.installationScript;
          })
      ) (import ../dev-shells {
        inherit inputs system;
        # `vlib.pkgsFor`, not flake-parts' `perSystem.pkgs` — keeps the pre-flake-parts layout.
        pkgs = vlib.pkgsFor system;
      });
  };
}
