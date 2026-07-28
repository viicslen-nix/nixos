# Dev shells, per system.
#
# Built via `vlib.pkgsFor` (allowUnfree, no extra overlays) rather than
# flake-parts' `perSystem.pkgs`, so they match the pre-flake-parts layout. The
# pre-commit hooks (parts/git-hooks.nix) install on shell entry. The formatter
# is owned by parts/treefmt.nix.
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
        pkgs = vlib.pkgsFor system;
      });
  };
}
