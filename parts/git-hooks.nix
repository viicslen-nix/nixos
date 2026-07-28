# Pre-commit hooks, via git-hooks.nix. Exposes `checks.pre-commit` (so
# `nix flake check` runs them) and an installation script wired into the dev
# shells (see dev-shells.nix), so the hooks install on `nix develop`.
{inputs, ...}: {
  imports = [inputs.git-hooks.flakeModule];

  perSystem = _: {
    pre-commit.settings.hooks = {
      alejandra.enable = true; # format nix
      deadnix.enable = true; # dead nix code (unused args/bindings)
      statix.enable = true; # nix anti-patterns
    };
  };
}
