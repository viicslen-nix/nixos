# CONTEXT

The story behind the overlays in this directory. They are exported by
`parts/overlays.nix` and consumed by the base preset as `outputs.overlays.*`.

## The overlays

- **`flake-inputs`** — for every flake input, aliases `pkgs.inputs.${flake}` to
  `inputs.${flake}.packages.${pkgs.system}` or
  `inputs.${flake}.legacyPackages.${pkgs.system}`.
- **`additions`** — brings the custom packages from the `pkgs` directory in as
  `pkgs.local`.
- **`unstable-packages` / `stable-packages`** — make the unstable and stable
  nixpkgs sets (declared in the flake inputs) reachable as `pkgs.unstable` and
  `pkgs.stable`.
- **`superset-fork`** — see below.
- **`modifications`** — whatever you want to overlay: changed versions,
  patches, compilation flags. See <https://nixos.wiki/wiki/Overlays>.

## `superset-fork`

Swaps the Superset desktop app for this user's fork (thread-style sidebar). An
overlay rather than a changed reference, so every consumer of
`pkgs.inputs.packages.superset.desktop` gets it and the swap is one line to
undo. Must be applied *after* `flake-inputs`, which is what creates
`pkgs.inputs` in the first place.

It takes the fork's `superset-desktop` attr — not `superset` — because the
Superset CLI installs `bin/superset` and both land in the same profile.

## `modifications.libdisplay-info_0_2`

nixpkgs dropped `libdisplay-info_0_2` on 2026-08-04 ("unused"), but niri-flake
still builds niri against 0.2 and asserts the version, so `pkgs.niri-unstable`
stops evaluating without it. We rebuild 0.2.0 from the 0.3 expression; drop
this once niri-flake moves to `libdisplay-info_0_3`.

## `modifications.pythonPackagesExtensions`

dpcontracts' README doctest (pulled in via nix-alien → pylddwrap → icontract)
calls `asyncio.get_event_loop()`, which no longer implicitly creates a loop on
python 3.14, failing the build. The extension skips that check.

## `t3code-version`

llm-agents' t3code trails upstream (0.0.40 against 0.0.42 releases), and the
version is a `let` binding inside its `unwrapped.nix` — not an argument — so
there is nothing to `override`. The overlay rebuilds it in place: new `src`,
new `pnpmDeps`/`cargoDeps` hashes, and `replaceStrings` over `preBuild` and
`installPhase`, which carry the old version and the old resource-monitor store
path as literals. Applied after `flake-inputs`, like `superset-fork`.

Two things a bump past 0.0.40 needs beyond hashes:

- **Electron 44.** Upstream's `preBuild` compares the major it expects against
  the one nixpkgs hands it and fails the build on a mismatch, so `electron_43`
  is overridden with `electron_44` — taken from llm-agents' own nixpkgs, the
  only one here new enough to carry it.
- **A seeded SPDX cache.** 0.0.42's web build generates a third-party licence
  manifest and downloads the licence texts it does not find under
  `.generated/third-party-licenses/spdx/<list version>`, which is gitignored —
  so in the sandbox it dies on `getaddrinfo EAI_AGAIN
  raw.githubusercontent.com`. `postPatch` copies the seven texts the config
  asks for into that directory. The list revision, the list version and the
  set of licence ids all live in `scripts/lib/third-party-licenses.ts` and
  `third-party-licenses.config.json`; re-read both on a bump.

Overriding at all voids `cache.numtide.com` for this package — the store path
no longer matches what numtide built — so t3code is a from-source build
(electron, a pnpm monorepo and a Rust helper) until llm-agents catches up.
Drop the overlay then.
