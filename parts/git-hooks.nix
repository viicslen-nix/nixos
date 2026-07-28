# Pre-commit hooks, via git-hooks.nix. Exposes `checks.pre-commit` (so
# `nix flake check` and CI run them) and an installation script wired into the
# dev shells (see dev-shells.nix), so the hooks install on `nix develop`.
#
# Scope: secrets only. Formatting is already gated by parts/treefmt.nix (which
# runs alejandra), so it is not duplicated here.
#
# deadnix and statix are deliberately NOT enabled as commit gates: both declare
# `pass_filenames = false` and scan from the repo root, so they ignore
# pre-commit's `excludes` and lint the flakes/* submodules — separate repos
# whose code is not ours to fix. They also surface stylistic findings (repeated
# key assignments) that `statix fix` cannot resolve automatically. Run them by
# hand when doing a cleanup pass:
#
#   nix run nixpkgs#deadnix -- --edit modules parts overlays dev-shells users hosts
#   nix run nixpkgs#statix -- fix modules parts overlays dev-shells users hosts
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

      hooks = {
        # Same tool CI runs (.github/workflows/gitleaks.yml), so local and CI
        # agree. It scans the tree itself, hence pass_filenames = false.
        # ripsecrets was tried first but flagged keybindings such as
        # `key = "Ctrl+Shift+Space"` as secrets.
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
