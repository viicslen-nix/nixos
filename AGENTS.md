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
  `defaultSystems`, `genSystems`, `pkgsFor`, and the namespaced helper sets
  `options` (`mkEnabledOption`, `mkDefaultAttrs`), `discovery` (`discover`,
  `mkTree`, `assertUnique`), `overlays` (`mkFlakeInputsOverlay`,
  `mkChannelOverlay`), `persistence`, `skills`. Reachable in modules as
  `inputs.self.lib`; from a `parts/` module use `inputs.viicslen-lib.lib`
  instead, since `parts/lib.nix` is what defines `self.lib`. Its `hosts.nix`,
  `modules.nix` and `umport.nix` have **no callers in this repo** — `parts/`
  and `discovery.nix` do that work now.
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
  *local* `path:.` build reads each subflake's dirty working tree. **No
  `path:./flakes/<x>` input carries a narHash in `flake.lock`** (verified for all
  ten), so committing inside the submodule is enough — a root re-lock changes
  nothing and `nix flake update <name>` produces an empty diff. `just
  update-subflake <name>` is still worth running when you want the subflake's
  *own* inputs bumped; its second step is a no-op for the root lock.
  What does bite: the flake source is `git+file://`, so a **new** file in a
  subflake is invisible until `git add`ed — `nix build` fails with
  `does not provide attribute 'packages.<system>.<name>'` rather than anything
  pointing at the real cause.
- **Update recipes.** `just update` updates every subflake *and* all root
  inputs; `just update-main` = root inputs only; `just update-input <x>` /
  `just update-subflake <x>` for one.
- **omniflake.** 20 dependencies are no longer flake inputs: they are pins in
  [omniflake](https://github.com/fzakaria/omniflake)'s `index.json`, fetched
  lazily at evaluation. The mapping (local name → index attribute) is the
  `omniInputs` set in `flake.nix`; it is merged into `inputs` before
  `mkFlake`, so `inputs.<name>` and `pkgs.inputs.<name>` are unchanged
  everywhere else and `nix.registry` still lists them (omniflake's loader sets
  `_type = "flake"`). Consequences: `just update-input omniflake` bumps all 20
  at once — home-manager included, so an HM bump is now an omniflake bump —
  and `just update-input disko` no longer resolves; `nix flake metadata` will
  not show them; the index keys on the *repository* name, so
  `vscode-server` is `nixos-vscode-server`, `git-hooks` is `git-hooks-nix`,
  `base16` is `base16-nix`, `jovian` is `jovian-nixos`, `llm-agents` is
  `llm-agents-nix` and `zen-browser` is `zen-browser-flake`. `stylix` keeps its
  name but the index holds `nix-community/stylix`, the repo `danth/stylix` was
  transferred to — same project, not a fork. Unification is by
  input *name* at every depth via `lib.withOverrides`, which is where the old
  `follows` lines went — including `systems = systems-linux`, so the
  darwin-stripping workaround still reaches `llm-agents`. An input stays real
  when something must `follows` it (`nixpkgs`, `systems-linux`), when it
  bootstraps `mkFlake` (`flake-parts`), when it is `flake = false`
  (the index holds flakes only), or when it simply is not indexed.
- **home-manager comes from omniflake, and unifies by self-reference.** The
  override set passes `inherit (omni) home-manager`, so plasma-manager,
  agenix and zen-browser all reach the one copy without home-manager being an
  input. It terminates because overrides apply to a flake's *inputs*, never to
  the flake being loaded — the same shape as omniflake's own `lib.unifyAll`.
  This was only possible after dropping the dead `home-manager` input from
  `flakes/zed` (declared, never read), which was the last `follows` line
  pointing at it. Verified: one rev across ours/plasma/agenix/zen.
- **Removing an `inputs.<x>.nixpkgs.follows` does not restore the old pin.**
  `nix flake lock` re-resolves that input from its `original` — a floating
  branch or channel URL — so dropping a follows moves the dependency
  *forward*, often past what its author tested or its cache was built
  against. Bit twice here (`tuicr`, `ghostty`). To put one back exactly, use
  `nix flake lock --override-input <x>/nixpkgs <the locked url/rev from git>`;
  note that writes a node with `lastModified` 1980 and no `rev`, so restore
  those two fields with `jq` if you want the lock byte-faithful. Verify with
  the *store path*, not the lock: it must match what the cache has.
- **crates.io 403s nix's User-Agent from this host.** A bare `curl` of
  `https://crates.io/api/v1/crates/<c>/<v>/download` returns **403**; the same
  URL with a browser UA returns 200, as does `static.crates.io`. nixpkgs'
  `importCargoLock` fetches the blocked URL, so any Rust package that has to
  *re-vendor* its crates dies on
  `error: cannot download download-<crate> from any mirror`. Already-realised
  store paths and cached vendor FODs mask it, so it only shows up when
  something forces a rebuild — bumping a Rust input, or repinning one's
  nixpkgs. This is why `tuicr` keeps its own nixpkgs pin; it is also waiting
  to bite the next `just update` that moves a Rust input.
- **The subflakes stay on their own inputs.** Only 5 of the ~35 inputs across
  `flakes/*` are in the index (emacs→`emacs-overlay`, lib→`systems`,
  neovim→`nvf`, niri→`niri-flake`, nixvim→`nixvim`), and adding omniflake to a
  subflake costs six lock nodes to remove one — a net loss in every case.
  `nvf` and `nixvim` are also deliberately pinned to a branch/tag the index
  does not carry. Don't "finish the migration" there.
- **Bumping local packages.** The recipes live in the subflake
  (`flakes/packages/Justfile`, implemented by `flakes/packages/scripts/packages.sh`);
  the root `Justfile` only aliases them. `just packages` lists the attrs; `just
  outdated` compares every one against upstream's latest version — GitHub
  releases, else npm / PyPI / the vendor's own endpoint (`latest_other` in the
  script; extend it there for a new upstream kind). Read-only, uses `gh` +
  `curl`; `-` = the repo has no matching release, e.g. rev-pinned plugins.
  `just bump <attr>` wraps `nix-update --flake`; the attr is the path under
  `by-name/` (`app-images.t3code`, `superset.cli`, bare `coderabbit`).
  Version autodetect only works for github/gitlab/pypi/npm/crates upstreams —
  otherwise pass `--version <x>` (or `--version skip` to refresh the hash of a
  re-uploaded binary). `vivaldi-stable` / `vivaldi-snapshot` are the exception:
  neither has a forge, so `bump` reads the newest build of that channel out of
  Vivaldi's apt index (`./scripts/packages.sh vivaldi-latest <channel>`). Their
  shared body lives in `flakes/packages/builders/vivaldi.nix`; `version` and
  `src` stay in the per-channel file because nix-update rewrites the file where
  `src` is defined. Multi-platform `fetchurl` needs a second pass with
  `--system aarch64-linux`. `just bump-all`
  sweeps every package carrying a src hash and lists the ones it couldn't
  resolve; `just bump-outdated` bumps exactly what `just outdated` flags.
  Remember to commit in the submodule; `git add` any new file first, or the
  flake cannot see it.
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
- **`lib` is extended repo-wide.** `parts/hosts.nix` passes
  `lib.extend (_: _: inputs.viicslen-lib.lib.options)` into `nixosSystem`, so
  every module reaches `mkEnabledOption` / `mkDefaultAttrs` / `mkDefaultRecursive`
  through its ordinary `lib` argument — no `inputs` arg, no
  `with inputs.self.lib;` preamble. It covers home-manager modules too, because
  home-manager builds its `extendedLib` from the lib it is handed
  (`nixos/common.nix`), not from `pkgs.lib`. Write
  `enable = mkEnabledOption (mdDoc name);`, never
  `mkEnableOption … // {default = true;}`. Two consequences: nixpkgs explicitly
  advises against extending `lib` when modules are shared, so anything importing
  this flake's `flake.modules.*` must extend its own lib the same way or reach
  the helpers at `inputs.viicslen-lib.lib.options`; and a new helper is only
  visible to modules once it is added to `options.nix` **and** the subflake is
  committed.
- **Container module helpers live in the lib subflake.**
  `inputs.self.lib.containers` provides `mkHostOption`, `mkMkcertDomains` and
  `mkTraefikLabels`; container modules take an `inputs` argument and
  `inherit` from it, the same way 19 other modules reach `persistence`.
  `mkTraefikLabels` deliberately omits `--network=local` so a container needing
  other flags first (local-ai's `--device`) can order them: write
  `extraOptions = ["--network=local"] ++ mkTraefikLabels {…};`. Label **order**
  is part of the systemd unit, so if you extend it, append rather than reorder.
- **Renamed attrs.** Prefer current names: `pkgs.<x>` over `pkgs.xorg.<x>`,
  `stdenv.hostPlatform.system` over `pkgs.system`. nixpkgs prints eval warnings
  for the old ones.
- **Two ways to get upstream AI skills.** Small, skill-only repos ride as a
  `flake = false` input (`mattpocock-skills`), bumped with `just update-input`.
  Repos that carry a lot of non-skill weight are vendored instead — there is no
  sparse fetch for a non-flake input, so an input would copy the whole thing
  into the store (effective-html is 22M for 148K of skills). `just vendor-skills`
  sparse-checks out the subtree listed in `scripts/skill-sources.tsv` into
  `hosts/_shared/presets/personal/ai/skills/`, stamping each directory with
  `.vendored-from` so the next run can prune what upstream deleted. **`git add`
  the result before evaluating** — the flake source is `git+file://`, so
  untracked skills are invisible to `nix eval` and to a rebuild, and the failure
  looks like the skill silently not existing.
- **AI skill helpers live in the `lib` subflake.** `flakes/lib/skills.nix`
  exports `mkSkillAttrSet` / `mkMarkdownAttrSet` (local directory → attrset),
  `fromInput` (coerce `"${input}/sub"` back to a real path), `selectFromInput`
  (many subpaths of an input at once, keyed by basename — the caller states the
  layout, so it works against any upstream repo), and `patchSkill src subs`.
  Reach them as `inputs.self.lib.skills.<x>`. **Wire new helpers into `flakes/lib/flake.nix`,
  not `flakes/lib/default.nix`** — the flake output is assembled inline in
  `flake.nix`; `default.nix` is a legacy entrypoint nothing imports, and editing
  only it leaves the helper invisible as `attribute 'skills' missing`. Note `just
  update-subflake lib` bumps the subflake's own nixpkgs pin, which is inert here
  because the root `follows` — and its root-lock step is a no-op, per
  **Submodules + locking** above.
- **Skills are pathlike-or-string.** `modules.programs.ai.skills` values reach
  home-manager's `claude-code` module, whose `mkSkillEntry` branches on
  `lib.hm.strings.isPathLike content && lib.pathIsDirectory content` to decide
  *symlink this directory to `skills/<name>/`* vs *write this value as
  `skills/<name>/SKILL.md`*. `isPathLike` accepts a path, a store-path
  **string**, or a derivation. A directory path is what you want for a
  multi-file skill; a plain string gives you a single `SKILL.md`.
- **Patching an upstream skill without forking it.** `skills` in the personal AI
  preset is three layers, last wins: `upstreamSkills` (verbatim, via
  `selectFromInput`) `//` `patchedSkills` `//` `mkSkillAttrSet ./skills` (a local
  directory, which shadows outright and loses all upstream updates — avoid for a
  skill you only want to tweak). The middle layer is `patchSkill src subs`: it
  `readFile`s the upstream `SKILL.md` and `replaceStrings` anchored spans, so
  `just update-input mattpocock-skills` keeps flowing in. Two things to know:
  the result is a **string**, so only single-file skills work this way (a
  multi-file one would need a `runCommand`, which costs an IFD — `pathIsDirectory`
  has to build the derivation to look inside it); and it **asserts** every `from`
  anchor is still present, because `replaceStrings` otherwise no-ops silently and
  hands back vanilla upstream with no signal. Anchor on spans that survive
  rewording, and keep the patch in
  `hosts/_shared/presets/personal/ai/skill-patches/<name>.nix`. The same value is
  forwarded to opencode/antigravity/copilot too — phrase harness-specific edits
  conditionally rather than naming one harness's tool imperatively.
- **`modules.programs.ai` never touches `~/.claude.json`.** MCP servers reach
  Claude Code as a generated `claude-code-home-manager` plugin (a `.mcp.json`
  in a plugin dir passed via `--plugin-dir` on the wrapped binary) — hence the
  `mcp__plugin_claude-code-home-manager_*` tool prefix. Anything still listed
  under `mcpServers` in `~/.claude.json` was added by `claude mcp add -s user`
  and shadows the Nix-provided copy; drop it with
  `claude mcp remove <name> -s user`. `~/.claude/settings.json` is likewise only
  written when `programs.claude-code.settings != {}` — owned by
  `modules/home-manager/programs/claude-code` (global prefs, marketplaces,
  enabled plugins), plus a hook block from every module that wants one —
  `modules.programs.ai`'s `integrations/{mempalace,superset}.nix` and
  `modules.programs.herdr.enableClaudeIntegration`. Hook lists for the same
  event concatenate, so modules never need to know about each other.
  Claude Code itself, and the mempalace/ponytail/superset hook installers,
  rewrite that file at runtime, so those edits land in `settings.json.backup`
  and are dropped on the next activation. Change settings in Nix, not in the TUI.

- **mcp-gateway scrubs the backend environment.** It spawns stdio backends with
  only `HOME`, `PATH`, `PWD`, `SHLVL` and `TMPDIR` plus the backend's own `env:`
  block; there is no inherit/passthrough switch. An agenix secret path is
  `${XDG_RUNTIME_DIR}/agenix/<name>`, so a wrapper that reads one must
  re-derive that variable itself (`''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}`)
  or the path collapses to `/agenix/<name>`. Compounding it, `export
  VAR="$(cat …)"` returns *export's* exit status, not the substitution's, so
  the failed read sails past `set -e` and the server starts on an **empty
  credential** — assign first, then export. This is exactly how prod-db broke:
  it died on `Access denied … (using password: NO)` while grafana silently
  served an empty token and still listed its 65 tools.
- **Private GitHub needs the token on two paths, in two formats.** Flake
  *inputs* are fetched by the **client** from `access-tokens` in
  `/etc/nix/nix.conf`; `pkgs.fetchurl` in a fixed-output derivation reads
  `impureEnvVars` from the **nix-daemon's** environment, so exporting
  `GITHUB_TOKEN` in your shell does nothing for it. `secrets/github/nix-token.age`
  holds the bare PAT and `system.activationScripts.nixTokenFiles` in `base`
  shapes both files (`/run/nix-daemon-env`, `/run/nix-access-tokens`). Don't
  "simplify" that to `writeText`: `/nix/store` is world-readable and
  substitutable, so a token in a derivation leaks. The script must stay
  `deps = ["agenix"]` and guard with `if`, not `exit` — activation snippets are
  concatenated into one script, and it runs under `set -e`.
- **Debugging a dead gateway backend.** Backend stderr is *not* journaled, and
  the gateway only reports `Backend timeout: Request timed out`, so the real
  error is invisible. Don't reproduce by running the wrapper from your shell or
  from `/proc/<gateway-pid>/environ` — both have the full environment the
  backend never gets, so a broken wrapper passes. Instead run a throwaway
  gateway on a spare port with a config naming just that backend, its command
  wrapped in a script that `exec`s the real one with `2>` redirected to a file.

## Keep docs current

These docs drift. When your change makes them wrong, fix them in the same task
(no separate ask needed):

- **README.md** — update when you add/remove a host, desktop environment, dev
  shell, or `just` recipe, or otherwise change user-facing architecture.
- **AGENTS.md (this file)** — update when you discover a new gotcha, add or
  rename a preset/subflake, or change a workflow an agent must follow. Keep it
  accurate over exhaustive; verify a claim (that a file, flag, or recipe exists)
  before adding it.
