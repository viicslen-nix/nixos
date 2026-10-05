# GitHub Workflows

## Checks (`checks.yml`)

Runs on every push to `main`, on pull requests, and on demand. It runs the
flake's own `checks` outputs, so CI and a local `nix flake check` agree:

- **`format-and-lint`** — builds `checks.x86_64-linux.{treefmt,pre-commit}`:
  alejandra + shfmt formatting, and the gitleaks / detect-private-keys
  pre-commit hooks. Fast; the primary gate.
- **`eval-hosts`** — matrix that evaluates each evaluable host's toplevel to a
  derivation (fast gate; does not build). `wsl` and `lenovo-legion-go` are
  excluded (see `parts/checks.nix`) because they currently fail to evaluate for
  pre-existing reasons. Targets the check attributes directly rather than
  `nix flake check`, which would evaluate *every* `nixosConfiguration` and trip
  over those two.

Nothing here builds the host toplevels or caches them — this workflow is
eval-only. (This used to be covered by garnix, which [shut
down](https://garnix.io/blog/shutting-down/) in July 2026.) The
`flakes/packages` locals therefore build from source on each host rebuild.

## Secret Scan (`gitleaks.yml`)

Runs gitleaks over the working tree, the same scan the pre-commit hook runs
locally.

## Build NixOS Host (`build-host.yml`)

Manually triggered. Builds one host, or all of them, and uploads the closure as
a NAR artifact, kept for `artifact_retention_days`.

## Shared setup (`.github/actions/setup-nix-build`)

Composite action used by the jobs above: frees runner disk space, installs Nix
with flakes, and configures the nix-community Cachix cache.
