# Pre-commit hooks, via git-hooks.nix. Secrets only — formatting is treefmt's job.
{inputs, ...}: {
  imports = [inputs.git-hooks.flakeModule];

  perSystem = {pkgs, ...}: {
    pre-commit.settings = {
      # Mirrors parts/treefmt.nix: flakes/* are submodules, and personal/ai/* is
      # vendored content read verbatim into the home config.
      excludes = [
        "^flakes/"
        "^hosts/_shared/presets/personal/ai/"
      ];

      # Don't add deadnix or statix here — they ignore `excludes` and lint the flakes/* submodules.
      hooks = {
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
