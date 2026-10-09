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

## `shells.nix`

Built via `vlib.pkgsFor` (allowUnfree, no extra overlays) rather than
flake-parts' `perSystem.pkgs`, so they match the pre-flake-parts layout. The
pre-commit hooks (`git-hooks.nix`) install on shell entry. The formatter is
owned by `treefmt.nix`.

## `disko.nix`

Each `../disko/<name>.nix` is a function of its parameters (`{device}`)
returning a disko module. Hosts receive the set as the `diskoLayouts`
specialArg and call it inside `imports`, which is why it is a specialArg and
not a `_module.args` entry inside the NixOS evaluation:

```nix
imports = [(diskoLayouts.btrfs-lvm {device = "/dev/disk/by-id/…";})];
```

Also exported as `flake.diskoLayouts`.

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

Scope: secrets, plus `statix check`. Formatting is gated by `treefmt.nix`, so
it is not duplicated here.

deadnix and statix run as treefmt formatters (`--edit` / `fix`), not as the
built-in git-hooks: those declare `pass_filenames = false` and scan from the
repo root, so they ignore pre-commit's `excludes` and lint the `flakes/*`
submodules — separate repos whose code is not ours to fix. treefmt hands each
tool its own file list, which already skips `flakes/*`.

`statix fix` silently skips lints it cannot rewrite — repeated keys (W20) are
the one that matters — so treefmt alone would let them in. The `statix-check`
hook catches those, scoping itself with statix's own `--ignore 'flakes/**'`
for the same submodule reason.

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

## `inventory/`

Answers "what does this host install, and which preset put it there?" without
anyone keeping a list by hand. `default.nix` exposes `flake.inventory.<host>` as
plain data; `inventory.sh` (the `just inventory` recipe) evaluates it and renders
it with the `*.jq` programs as the terminal view, markdown, or the cross-host table
in `docs/inventory/README.md`. The terminal view fits its width: the leading
columns are capped to what 90% of rows need, and only rows that still overflow
stack their source(s) underneath. Stacking every row of a section whenever one
outlier (a `1.7-beta+date=…` version) overflowed doubled the Packages list.
Piped output is never stacked, so `grep` sees each entry and its source on one
line. Under nushell, `just inventory` is a custom command
(`modules/home-manager/programs/nushell/inventory.nu`) that reads `--json` and
returns one flat table (`scope kind name detail source upstream`). Nushell
then handles the width, and the result can be queried. It hands off to the
real `just` when the nearest justfile isn't this repo's, so another project's
`inventory` recipe still works. It's a directory, not a file, so the script and
renderers sit beside the module; the non-recursive `parts/` import loads it
through `default.nix`.

Attribution comes from `options.<path>.definitionsWithLocations`: every
definition carries the file that made it, so `environment.systemPackages` splits
into `presets/work`, `hosts/dostov-dev`, `modules/nixos/programs/podman`, … with
no annotation in the config. Home-manager users are reached through
`options.home-manager.users.valueMeta.attrs.<user>.configuration`. A file under
`self.outPath` is a repo source; anything else is upstream (nixpkgs,
home-manager, stylix, …). A package added by a module shows that module's file,
not the preset that enabled the module. The `modules` section bridges that gap,
because it lists who set each `enable`.

The closing Duplicates section (`--dupes` shows only it) lists every package
name defined in more than one place, file or scope, where at least one of them
is a repo file. It enforces the preset rule that a raw list never repeats what a
module installs: `git` in `presets/base` next to home-manager's
`programs/git.nix` shows up there. It is matched by name, so two outputs of one
package (`gcc` vs `gcc-wrapper`) are not caught. A subflake module imported
without a `_file` (dms) is credited to the preset that imported it, so its own
system and home copies (`dms-shell`, `cava`) show as `presets/desktop` twice.
It reports and never fails: a check would have to evaluate every host.

Traps hit while building it:

- `tryEval` catches `throw`/`assert` only. Rename aliases (`visible = false`)
  can `abort` when read (`services.frp.enable`), so hidden `enable`s are never
  evaluated. They would also report their target twice.
- Sub-feature `enable`s often default to true under a disabled service
  (`services.akkoma.initDb`), so the walk stops at any level whose own `enable`
  is false.
- Home-manager's `nixgl.nix` puts `mkIf` on list *elements*, which the merge
  never discharges; `toString` on one is a type error, not a catchable throw.
  Packages are unwrapped first.
- nixpkgs folds every `users.users.<u>.packages` (home-manager's packages,
  with `useUserPackages`) into `systemPackages` from `users-groups.nix`. That
  definition is dropped so home packages aren't listed twice.
- An inline `home-manager.sharedModules` entry (an attrset or function, not a
  path) has no file, so everything it defined was credited to home-manager's
  own `nixos/common.nix` and counted as upstream: DMS, its packages and its
  `dms` unit looked like nobody in the repo had enabled them. The host is
  re-evaluated with `extendModules`, each such entry wrapped in
  `{_file = <the file that added it>; imports = [m];}` under `mkForce`. Only
  the extended eval is read, so this costs no second evaluation. The credit
  goes to the import site, e.g. `presets/desktop` for the dms subflake.
- Visible aliases (`services.sshd` → `services.openssh`) repeat their target.
  They're recognised by having no `default` and no definitions. Never read
  `description` to spot them: modules here write `mkEnabledOption (mdDoc …)`,
  and forcing that is an `undefined variable` error, which `tryEval` can't
  catch either.

Sub-feature toggles were most of the noise (`programs.direnv.nix-direnv`,
`services.pipewire.pulse`, `services.zfs.trim`), so the walk prunes them. In
upstream trees it doesn't descend below a level the repo enabled, and it drops
nested (`ns.a.b`) toggles that no repo file set. A level enabled only upstream
(`services.displayManager` from `greetd.nix`) is still descended, so a
repo-set `services.gnome.gnome-keyring` survives. Under `modules.*` only
direct sub-features are dropped (`modules.programs.mkcert.rootCA`); members of
a group without its own `enable` stay (`modules.programs.ai.integrations.*`).

Only `services`/`programs`/`virtualisation` and our `modules` trees are walked.
Units are listed only when the repo creates them: upstream units are hundreds
of lines of noise, and one the repo merely tweaks (`nix-daemon`, `greetd`, the
`podman-*` units `oci-containers` generates) isn't installed by it. A unit set
from several repo files is one row with each source. One host evaluates in
about 10 s, and `--all` over five hosts takes about 40 s.

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

A preset is a bundle of configuration in `../presets/<name>`.
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
`checks.formatting` gate. This owns `formatter`, so `shells.nix` no longer
sets it.

deadnix and statix rewrite code, so they carry a lower `priority` than
alejandra: treefmt runs them first and alejandra formats what they leave.
