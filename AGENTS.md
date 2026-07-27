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
  `presets = [ … ]` list. `desktop` carries graphical-only bits (the
  `nixpkgs-wayland` overlay and its cache).
- **subflake** — a git submodule flake under `flakes/*` (`lib`, `packages`,
  `opencode`, `zed`, `neovim`, `nixvim`, `niri`, `hyprland`, `dms`). Each is a
  separate upstream repo (`viicslen-nix/*`).
- **vlib / viicslen-lib** — helper library exported from `flakes/lib`; provides
  `mkNixosConfigurations`, `genSystems`, `pkgsFor`,
  `modules.autoImportRecursive`, etc. Reachable in modules as `inputs.self.lib`.
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
- **Renamed attrs.** Prefer current names: `pkgs.<x>` over `pkgs.xorg.<x>`,
  `stdenv.hostPlatform.system` over `pkgs.system`. nixpkgs prints eval warnings
  for the old ones.

## Keep docs current

These docs drift. When your change makes them wrong, fix them in the same task
(no separate ask needed):

- **README.md** — update when you add/remove a host, desktop environment, dev
  shell, or `just` recipe, or otherwise change user-facing architecture.
- **AGENTS.md (this file)** — update when you discover a new gotcha, add or
  rename a preset/subflake, or change a workflow an agent must follow. Keep it
  accurate over exhaustive; verify a claim (that a file, flag, or recipe exists)
  before adding it.
