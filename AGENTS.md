# AGENTS.md

Instructions for AI coding agents (Claude Code, Opencode, Antigravity, and any
other assistant) working in this repository. `CLAUDE.md` is a symlink to this
file. For general architecture, the host list, and feature overview, see
[README.md](./README.md).

## Resource safety — CRITICAL

This repo *is* a live NixOS host (`/etc/nixos`). A runaway `nix` evaluation or
build can exhaust RAM and lock the user out of their own machine — this has
already happened. Treat every heavy Nix invocation as dangerous.

- **One at a time.** Never run more than one `nix` process concurrently. Never
  background a Nix eval/build (`&`, `run_in_background`) or stack them — they
  pile up and OOM the box.
- **Cap the memory.** Wrap any whole-system evaluation, build, or dry-build in a
  memory-limited scope so the kernel kills the command instead of freezing the
  session:

  ```bash
  systemd-run --user --scope -p MemoryMax=8G -p MemorySwapMax=0 \
    nix eval .#nixosConfigurations.<host>.config.<option>
  ```

  If user-cgroup delegation is unavailable, fall back to
  `GC_MAXIMUM_HEAP_SIZE=8G nix …`.
- **Builds** additionally pass `--cores 3 --max-jobs 2`
  (e.g. `nixos-rebuild … --cores 3 --max-jobs 2`).
- **Check RAM first.** Run `free -g`; if free memory is tight, stop and tell the
  user — do not launch the eval.
- **Prefer narrow evals.** Validate a change by evaluating the *specific option
  you touched* (e.g. `…config.programs.ssh.settings`), never
  `…system.build.toplevel` by default.
- **A full capped dry-build** (`nixos-rebuild dry-build` or a `toplevel` eval)
  **is allowed only after asking the user first** — and still capped, single,
  and foreground.
- **Never run `switch`/`boot`/`test` yourself.** The user runs real rebuilds.
  You edit files and, at most, do the capped checks above.

## Working style

- Be concise. Confirm completions in a line; reserve detail for errors or when
  asked.
- Fix root causes, not symptoms — grep every caller before patching one path.
- If a change is shown not to work, roll it back before layering another fix.
  Don't stack speculative fixes.

## Vocabulary

- **host** — a machine config under `hosts/<name>/`. The set of hosts and the
  presets each one receives is declared in `hosts/default.nix`.
- **preset** — a composable module bundle in `hosts/_shared/presets/<name>`
  (`base`, `desktop`, `work`, `personal`, `linode`). Hosts opt in via their
  `presets = [ … ]` list. `base` is universal/server-safe; `desktop` carries
  **all** graphical/physical-machine config (fonts, printing, avahi, libinput,
  compositor imports, wayland overlay + caches, bluetooth, GUI env). Every
  graphical host — including the KDE handheld — must list `desktop`.
- **`modules.presets.desktop.enable`** — a flag declared in `base` (default
  false) and set true by the `desktop` preset. `work`/`personal` gate their
  GUI-only packages behind it (`lib.optionals config.modules.presets.desktop.enable [ … ]`)
  so headless hosts (WSL) don't pull GUI apps. In home-manager, read it via
  `osConfig.modules.presets.desktop.enable`.
- **parts/** — the root flake is a [flake-parts](https://flake.parts) flake.
  `flake.nix` only declares inputs; every `.nix` file under `parts/` is a
  flake-parts module and is auto-imported (`systems`, `lib`, `overlays`,
  `dev-shells`, `modules`, `hosts`). Add a concern by dropping in a file.
- **module discovery** — `parts/modules.nix` collects every `default.nix` under
  `modules/{nixos,home-manager}` at any depth. A path component starting with
  `_` is skipped, which is how non-module helpers opt out (e.g.
  `services/impermanence/_presets`, whose `default.nix` takes `systemConfig`).
- **subflake** — a git submodule flake under `flakes/*` (`lib`, `packages`,
  `opencode`, `zed`, `neovim`, `nixvim`, `niri`, `hyprland`, `dms`, `emacs`).
  Each is a separate upstream repo (`viicslen-nix/*`).
- **vlib / viicslen-lib** — helper library exported from `flakes/lib`; provides
  `defaultSystems`, `genSystems`, `pkgsFor`, `persistence`, etc. Reachable in
  modules as `inputs.self.lib`. Its `hosts.mkNixosConfigurations` and
  `modules.autoImportRecursive` are no longer used by this repo — `parts/`
  does that work now.
- **overlays** — `overlays/default.nix` exposes `pkgs.unstable`, `pkgs.stable`,
  `pkgs.local`, `pkgs.inputs.<flake>`, and package `modifications`.
- **modules** — everything under `modules/nixos` and `modules/home-manager` is
  auto-imported (`autoImportRecursive`); a new module is available once its file
  exists, then enabled per host/user.
- **nh** — `nh os …`, the rebuild helper wrapped by the `just upgrade` recipe.
- **just** — the task runner; `Justfile` holds the canonical recipes. Don't
  hand-roll `nixos-rebuild` / `nix flake update` when a recipe already exists.

## Gotchas & workflows

- **Submodules + locking.** `flake.nix` sets `self.submodules = true`, so a
  *local* `path:.` build reads each subflake's dirty working tree — but the root
  lock still pins every `path:./flakes/<x>` by narHash. After editing a subflake
  you must commit inside that submodule **and** re-lock the root input
  (`just update-subflake <name>`, or `nix flake update <name>`), or the change
  isn't picked up reproducibly.
- **Update recipes.** `just update` updates every subflake *and* all root
  inputs; `just update-main` = root inputs only; `just update-input <x>` /
  `just update-subflake <x>` for one.
- **Bumping local packages.** `just packages` lists the attrs; `just outdated`
  compares every GitHub-sourced one against upstream's latest release (read-only,
  uses `gh`; `-` = the repo has no matching release, e.g. rev-pinned plugins);
  `just bump <attr>` wraps `nix-update --flake` inside
  `flakes/packages`; the attr is the path under `by-name/` (`app-images.t3code`,
  `superset.cli`, bare `coderabbit`). Version autodetect only works for
  github/gitlab/pypi/npm/crates upstreams — otherwise pass `--version <x>` (or
  `--version skip` to refresh the hash of a re-uploaded binary). Multi-platform
  `fetchurl` needs a second pass with `--system aarch64-linux`. `just bump-all`
  sweeps every package carrying a src hash and lists the ones it couldn't
  resolve; `just bump-outdated` bumps exactly what `just outdated` flags.
  Remember to commit in the submodule + `just update-subflake packages`.
- **Local packages must interpolate the version into the tag.** Write
  `tag = "v${version}"` (or `"v${finalAttrs.version}"`), never a literal
  `rev = "v3.2.1"` — with a literal rev, nix-update rewrites `version` only, so
  the package silently keeps building the old source at the old hash.
- **Binary caches.** Substituters live in the `base` preset plus the `desktop`
  preset. The bleeding-edge `nixpkgs-wayland` overlay and its cache are scoped to
  `desktop` (graphical hosts only) — don't move them back into `base`, or
  WSL/headless hosts recompile the whole Wayland closure from source.
- **`useGlobalPkgs`.** `home-manager.useGlobalPkgs = true`, so any hm-level
  `nixpkgs.overlays` / `nixpkgs.config` is **ignored at runtime** and only emits
  a deprecation warning. Apply overlays at the system level, not in hm modules.
- **Local packages have no cache.** `flakes/packages` (superset, php, custom
  scripts, …) builds from source on every input bump — expect slow rebuilds
  there, and note the lantian/CachyOS cache can be flaky/down.
- **flake-parts normalises module outputs.** Entries in `flake.nixosModules` /
  `flake.homeManagerModules` get wrapped into `{_class; _file; imports;}`. Code
  that treats an attrset value as "a category of modules" will destructure that
  wrapper and feed the literal string `"nixos"` into an `imports` list; the
  error is `string 'nixos' doesn't represent an absolute path`, and the trace
  points at `lib/modules.nix`, never at the real culprit. Pass raw module lists
  around via `_module.args` instead.
- **Everything embeds the flake's own hash.** `nix.registry` maps every input,
  including `self`, so `/etc/nix/path/*` and `nix/registry.json` contain the
  flake source path — and `containers/{qdrant,buggregator}` mount
  `${./config}`. Any file edit therefore changes the toplevel `drvPath`. To
  check a refactor is behaviour-preserving compare the **`system-path`
  derivation**, the `/etc` entry names, and the systemd unit names — not the
  toplevel hash.
- **Renamed attrs.** Prefer current names: `pkgs.<x>` over `pkgs.xorg.<x>`,
  `stdenv.hostPlatform.system` over `pkgs.system`. nixpkgs prints eval warnings
  for the old ones.
- **Two ways to get upstream AI skills.** Small, skill-only repos ride as a
  `flake = false` input (`mattpocock-skills`), bumped with `just update-input`.
  Repos that carry a lot of non-skill weight are vendored instead — there is no
  sparse fetch for a non-flake input, so an input would copy the whole thing
  into the store (effective-html is 22M for 148K of skills). `just vendor-skills`
  sparse-checks out the subtree listed in `tools/skill-sources.tsv` into
  `hosts/_shared/presets/personal/ai/skills/`, stamping each directory with
  `.vendored-from` so the next run can prune what upstream deleted. **`git add`
  the result before evaluating** — the flake source is `git+file://`, so
  untracked skills are invisible to `nix eval` and to a rebuild, and the failure
  looks like the skill silently not existing.
- **AI skills sourced from a flake input need a real path.** `modules.programs.ai.skills`
  values reach home-manager's `claude-code` module, which branches on
  `lib.isPath` to decide *copy this directory* vs *write this string as the
  file body* — hand it a string and you get a `SKILL.md` whose contents are a
  store path. A flake input's `outPath` **is** a string, and `/. + "${input}/x"`
  throws `a string that refers to a store path cannot be appended to a path`.
  The idiom that works is
  `/. + (builtins.unsafeDiscardStringContext "${inputs.<x>}/…")`; discarding the
  context is safe here only because a flake input is a source that is already
  realised at eval time, never a derivation that still needs building. See
  `hosts/_shared/presets/personal/ai/default.nix`.

## Keep docs current

These docs drift. When your change makes them wrong, fix them in the same task
(no separate ask needed):

- **README.md** — update when you add/remove a host, desktop environment, dev
  shell, or `just` recipe, or otherwise change user-facing architecture.
- **AGENTS.md (this file)** — update when you discover a new gotcha, add or
  rename a preset/subflake, or change a workflow an agent must follow. Keep it
  accurate over exhaustive; verify a claim (that a file, flag, or recipe exists)
  before adding it.
