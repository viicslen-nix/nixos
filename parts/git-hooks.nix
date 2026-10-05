# Pre-commit hooks, via git-hooks.nix. Secrets, plus the statix lints treefmt cannot fix.
{inputs, ...}: {
  imports = [inputs.git-hooks.flakeModule];

  perSystem = {pkgs, ...}: {
    pre-commit.settings = {
      # Mirrors parts/treefmt.nix: flakes/* are submodules.
      excludes = ["^flakes/"];

      # Not the built-in deadnix/statix hooks — they ignore `excludes` and lint the flakes/* submodules.
      hooks = {
        # treefmt runs `statix fix`, which skips unfixable lints (repeated keys); this fails on them.
        statix-check = {
          enable = true;
          name = "statix check";
          entry = "${pkgs.statix}/bin/statix check --ignore 'flakes/**'";
          pass_filenames = false;
          files = "\\.nix$";
        };

        # gitleaks scans the tree itself, so `pass_filenames` must stay false.
        gitleaks = {
          enable = true;
          name = "gitleaks";
          entry = "${pkgs.gitleaks}/bin/gitleaks dir --no-banner --redact";
          pass_filenames = false;
        };

        detect-private-keys.enable = true;
      };
    };
  };
}
