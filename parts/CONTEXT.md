# CONTEXT

The story behind the flake-parts modules in this directory. Every `.nix` file
here is auto-imported by `flake.nix` (non-recursively) — see the repo-root
[CONTEXT.md](../CONTEXT.md) for that wiring.

## `checks.nix`

`nix flake check` builds each host's toplevel, so CI can gate on a full
evaluation + build of every configuration. Replaces the hand-rolled
`just build-all` bash loop.

`wsl` and `lenovo-legion-go` are intentionally excluded: they currently fail to
evaluate for reasons that predate this work (wsl's `nixpkgs.hostPlatform` type
conflict; lenovo's missing `inputs.chaotic`). Add them back once fixed.

The filter keys off the host NAME only — never the evaluated config — so
listing checks does not force a (possibly failing) host to evaluate. Every host
is `x86_64-linux`, so the checks are only emitted there.

## `dev-shells.nix`

Built via `vlib.pkgsFor` (allowUnfree, no extra overlays) rather than
flake-parts' `perSystem.pkgs`, so they match the pre-flake-parts layout. The
pre-commit hooks (`git-hooks.nix`) install on shell entry. The formatter is
owned by `treefmt.nix`.

## `flake-modules.nix`

Enables flake-parts' native dendritic module output,
`flake.modules.<class>.<name>`. The outer attribute is the module class
(`nixos`, `homeManager`, `generic`), so it transposes both classes uniformly
and applies the correct `_class` — replacing the hand-declared
`flake.homeManagerModules` option we previously needed.

## `git-hooks.nix`

Exposes `checks.pre-commit` (so `nix flake check` and CI run them) and an
installation script wired into the dev shells, so the hooks install on
`nix develop`.

Scope: secrets only. Formatting is already gated by `treefmt.nix` (which runs
alejandra), so it is not duplicated here.

deadnix and statix are deliberately NOT enabled as commit gates: both declare
`pass_filenames = false` and scan from the repo root, so they ignore
pre-commit's `excludes` and lint the `flakes/*` submodules — separate repos
whose code is not ours to fix. They also surface stylistic findings (repeated
key assignments) that `statix fix` cannot resolve automatically. Run them by
hand when doing a cleanup pass:

```bash
nix run nixpkgs#deadnix -- --edit modules parts overlays dev-shells users hosts
nix run nixpkgs#statix -- fix modules parts overlays dev-shells users hosts
```

gitleaks is the same tool CI runs (`.github/workflows/gitleaks.yml`), so local
and CI agree. It scans the tree itself, hence `pass_filenames = false`.
ripsecrets was tried first but flagged keybindings such as
`key = "Ctrl+Shift+Space"` as secrets.

## `hosts.nix`

The host list, and the presets each host receives, are declared in
`../hosts/default.nix`. Hosts and presets reach the registered modules through
the `nixosModules` / `homeModules` specialArgs, e.g.

```nix
{nixosModules, ...}: { imports = with nixosModules; [docker steam]; }
```

`extendedLib` is why every module reaches the repo-wide option helpers through
its ordinary `lib` argument, rather than each one importing them. home-manager
derives its own `extendedLib` from the lib it is handed (`nixos/common.nix`),
so this covers home-manager modules too.

Caveat: modules exported via `flake.modules.*` now assume this extension. An
outside consumer importing them must extend their lib the same way, or reach
the helpers directly at `inputs.viicslen-lib.lib.options`.

## `modules.nix`

Every `default.nix` under `../modules/{nixos,home-manager}` is itself a
flake-parts module registering one entry under `flake.modules.nixos.<name>` or
`flake.modules.homeManager.<name>` (the native dendritic output, enabled in
`flake-modules.nix`), named after its directory. Adding a module is just adding
a file, at any depth.

`flake.modules.<class>` is flat within a class. To keep the directory
namespaces at import sites we build a nested view over it and hand that to
hosts as the `nixosModules` / `homeModules` specialArgs:

```nix
imports = with nixosModules; [hardware.nvidia programs.docker];
```

A directory that is both a module and a namespace (`containers/default.nix`,
which declares the settings its children read) is reachable as
`<namespace>.base`.

Convention: a path component starting with `_` is skipped, for helpers that are
not modules (e.g. `services/impermanence/_presets`, whose `default.nix` takes a
`systemConfig` argument).

The walk itself lives in the lib subflake (`discovery.nix`) — it is pure
path-and-attrset work, parameterised by the root and the registry.

## `packages.nix`

Re-exports the local packages from the `packages` subflake as this flake's own
`packages.<system>.<name>`, so `nix build .#superset` works and CI can build
and cache them. They are otherwise only reachable as `pkgs.inputs.packages.*`
inside modules.

## `presets.nix`

A preset is a bundle of configuration in `../hosts/_shared/presets/<name>`.
Hosts opt in through their `presets = [ … ]` list in `../hosts/default.nix`;
publishing them here also makes them reachable as
`self.nixosModules.presets.<name>` from outside the flake.

They are deliberately NOT under `flake.nixosModules`: that attrset is the pool
of feature modules every host imports, whereas presets are selected per host.

## `systems.nix`

Which systems the per-system outputs (packages, devShells, formatter) are
generated for. Sourced from viicslen-lib so it stays in step with the helpers
that used to build these outputs by hand.

## `treefmt.nix`

Formatting, via treefmt-nix. Provides `nix fmt` (multi-language) and a
`checks.formatting` gate. This owns `formatter`, so `dev-shells.nix` no longer
sets it.
