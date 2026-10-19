# GitHub Workflows

## Checks (`checks.yml`)

Runs on every push to `main`, on pull requests, and on demand. It runs the
flake's own `checks` outputs, so CI and a local `nix flake check` agree:

- **`format-and-lint`** — builds `checks.x86_64-linux.{treefmt,pre-commit}`:
  treefmt (deadnix, statix, alejandra, shfmt) must leave the tree unchanged,
  and the gitleaks / detect-private-keys / `statix check` pre-commit hooks
  must pass. Fast; the primary gate.
- **`eval-hosts`** — matrix that evaluates each evaluable host's toplevel to a
  derivation (fast gate; does not build). `wsl` and `lenovo-legion-go` are
  excluded (see `parts/checks.nix`) because they currently fail to evaluate for
  pre-existing reasons. Targets the check attributes directly rather than
  `nix flake check`, which would evaluate *every* `nixosConfiguration` and trip
  over those two.

This workflow is eval-only; caching is `cache.yml`'s job.

## Cache (`cache.yml`)

Runs on every push to `main` and on demand. `.github/scripts/cache.sh`
dry-runs each evaluable host's toplevel, keeps the derivations that would be
built whose names match `.github/cache-allowlist`, builds them and pushes
their closures to the public `viicslen-nix` Cachix cache (5 GB free tier).
Paths already on cache.nixos.org are skipped by Cachix itself.

To cache another package, add its name to the allowlist — free software
only, the cache is public. Needs the `CACHIX_AUTH_TOKEN` repository secret.

## Secret Scan (`gitleaks.yml`)

Runs gitleaks over the working tree, the same scan the pre-commit hook runs
locally.

## Build NixOS Host (`build-host.yml`)

Manually triggered. Builds one host, or all of them, and uploads the closure as
a NAR artifact, kept for `artifact_retention_days`.

## Shared setup (`.github/actions/setup-nix-build`)

Composite action used by the jobs above: frees runner disk space, installs Nix
with flakes, and configures the nix-community Cachix cache.
