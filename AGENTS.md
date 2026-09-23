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
- **Read `CONTEXT.md` before you touch a directory.** A directory may hold a
  `CONTEXT.md` carrying the story behind its files — what was tried, why the
  obvious shape is wrong, what it cost. Nothing loads it for you and no comment
  points at it: check for one in the directory you are editing and in each
  parent up to the repo root, as part of reading the code, every time.
- **Context goes in `CONTEXT.md`, not in the code.** Write the *why* there,
  in the directory it concerns — the repo root included — creating the file
  when a directory earns one. This file holds the rules, vocabulary and
  workflows an agent follows; `CONTEXT.md` holds the story behind what is
  already written. Keep each fact in exactly one of the two.
- **Never put a dotfile or dotdir directly in `$HOME`.** Config belongs in
  `$XDG_CONFIG_HOME`, mutable data in `$XDG_DATA_HOME`, logs/history in
  `$XDG_STATE_HOME`, throwaway output in `$XDG_CACHE_HOME` — read each with its
  spec default (`''${XDG_CONFIG_HOME:-$HOME/.config}`), never hardcoded. This
  covers home-manager `home.file.".foo"`, an `age.secrets.<n>.path`, and any
  wrapper script that invents a private directory. A tool that only offers a
  `$HOME`-relative knob gets wrapped with the XDG path, not accommodated.
- **Comments in `.nix` files are one line, at the trap they guard.** A line
  that must not be "simplified" — a `follows` that must stay absent, a label
  order baked into a systemd unit, a literal nix cannot compute — carries a
  one-line warning where an editor will hit it. The reasoning behind it lives
  in `CONTEXT.md`; the comment says what not to do, not where to read more.

## Vocabulary

- **host** — a machine config under `hosts/<name>/`. The set of hosts and the
  presets each one receives is declared in `hosts/default.nix`.
- **preset** — a composable module bundle in `hosts/_shared/presets/<name>`
  (`base`, `desktop`, `work`, `personal`, `linode`). Hosts opt in via their
  `presets = [ … ]` list. `base` is universal/server-safe; `desktop` carries
  **all** graphical/physical-machine config (fonts, printing, avahi, libinput,
  compositor imports, wayland overlay + caches, sound, bluetooth, grub-on-EFI
  loader defaults, GUI env). Every
  graphical host — including the KDE handheld — must list `desktop`.
- **`modules.presets.desktop.enable`** — a flag declared in `base` (default
  false) and set true by the `desktop` preset. `work`/`personal` gate their
  GUI-only packages behind it (`lib.optionals config.modules.presets.desktop.enable [ … ]`)
  so headless hosts (WSL) don't pull GUI apps. In home-manager, read it via
  `osConfig.modules.presets.desktop.enable`.
- **parts/** — the root flake is a [flake-parts](https://flake.parts) flake.
  `flake.nix` only declares inputs; every `.nix` file under `parts/` is a
  flake-parts module and is auto-imported (`systems`, `lib`, `overlays`,
  `dev-shells`, `modules`, `hosts`) via `vlib.umport { path = ./parts;
  recursive = false; }`. Add a concern by dropping in a file — but note the
  non-recursive call means a *subdirectory* of `parts/` is imported as a whole
  (flake-parts resolves its `default.nix`), not walked file by file.
- **module discovery** — `parts/modules.nix` collects every `default.nix` under
  `modules/{nixos,home-manager}` at any depth. A path component starting with
  `_` is skipped, which is how non-module helpers opt out (e.g.
  `services/impermanence/_presets`, whose `default.nix` takes `systemConfig`).
  Each entry is wrapped with a `key` (`nixos:<name>` / `homeManager:<name>`)
  so two presets can import the same module: the module system only dedupes
  imports by `key`, and the flake-parts wrappers carry none, so without it a
  double import fails with `option … is already declared`.
- **subflake** — a git submodule flake under `flakes/*` (`lib`, `packages`,
  `opencode`, `zed`, `neovim`, `nixvim`, `niri`, `hyprland`, `dms`, `emacs`).
  Each is a separate upstream repo (`viicslen-nix/*`).
- **vlib / viicslen-lib** — helper library exported from `flakes/lib`; provides
  `defaultSystems`, `genSystems`, `pkgsFor`, and the namespaced helper sets
  `options` (`mkEnabledOption`, `mkDefaultAttrs`), `discovery` (`discover`,
  `mkTree`, `assertUnique`), `overlays` (`mkFlakeInputsOverlay`,
  `mkChannelOverlay`), `omni` (`mkInputs`), `persistence`,
  `skills`. Reachable in modules as
  `inputs.self.lib`; from a `parts/` module use `inputs.viicslen-lib.lib`
  instead, since `parts/lib.nix` is what defines `self.lib`. Its `hosts.nix` and
  `modules.nix` have **no callers in this repo** — `parts/` and `discovery.nix`
  do that work now. `umport` has exactly one: `flake.nix` imports `parts/` with
  it (`recursive = false`).
- **overlays** — `overlays/default.nix` exposes `pkgs.unstable`, `pkgs.stable`,
  `pkgs.local`, `pkgs.inputs.<flake>`, and package `modifications`.
- **modules** — everything under `modules/nixos` and `modules/home-manager` is
  auto-imported (`autoImportRecursive`); a new module is available once its file
  exists, then enabled per host/user.
- **`modules.desktop.shell`** — which shell autostarts in a graphical session
  (`dms`, `caelestia`, `exo`, `noctalia`, `none`; `caelestia` runs its Nilastia fork under niri). Compositors start the empty
  `desktop-shell.target` and never name a shell; each shell binds its own
  service to that target, and only the selected one is defined. Declared in
  `modules/nixos/desktop/shell`, which the `desktop` preset imports. The
  dank-greeter is independent of it. See that directory's `CONTEXT.md`.
- **`modules.desktop.monitors`** — output layout keyed by connector name
  (`position`, `scale`, `rotation`), translated into both niri `outputs` and
  Hyprland `monitor`. Declared in `modules/nixos/desktop/monitors`, imported by
  the `desktop` preset. Rotation is applied before positioning, so a portrait
  output is 1080 wide.
- **`modules.containers.settings`** — the one place the container engine is
  configured: `backend` (`"docker"` / `"podman"`) plus the engine-agnostic
  `nvidiaSupport`, `storageDriver` and `allowTcpPorts`. `programs.docker` /
  `programs.podman` each default `enable` to `backend == "<self>"` and read the
  rest from here, so both can be imported and a host sets only these. Don't add
  a per-engine `enable = true` or duplicate a knob onto `programs.<engine>`.
- **nh** — `nh os …`, the rebuild helper wrapped by the `just upgrade` recipe.
- **just** — the task runner; `Justfile` holds the canonical recipes. Don't
  hand-roll `nixos-rebuild` / `nix flake update` when a recipe already exists.

## Gotchas & workflows

- **Submodules + locking.** `flake.nix` sets `self.submodules = true`, so a
  *local* `path:.` build reads each subflake's dirty working tree. No
  `path:./flakes/<x>` input carries a narHash in `flake.lock`, so a change to a
  subflake's *files* needs only a commit inside the submodule. Its *inputs* do
  not work that way: **hosts build the root lock's pins, never the
  subflake's.** The root `flake.lock` holds its own copy of every transitive
  node a subflake doesn't `follows` away, and reads the subflake's `flake.lock`
  only when it (re-)locks that input — `nix flake update <name>` copies the
  subflake's pins over. So a bump committed to `flakes/<x>/flake.lock` changes
  nothing a host builds until the root runs `nix flake update <x>`, and the
  same re-lock is what adds or drops nodes when a subflake's input set changes
  (dropping the hyprland subflake's inputs removed 63 root nodes). The drift is
  silent: the root's dms node sat at `8594a41` while `flakes/dms` had moved to
  `c8ec045`. Compare
  `jq -r --arg i <input> '.nodes[.nodes["<root-input>"].inputs[$i]].locked.rev' flake.lock`
  with
  `jq -r --arg i <input> '.nodes[.nodes[.root].inputs[$i]].locked.rev' flakes/<dir>/flake.lock`;
  `<root-input>` is the directory name except for `flakes/lib`, which the root
  calls `viicslen-lib`. A `follows` input has no node of its own and cannot
  drift.
  Also: the flake source is `git+file://`, so a **new** file in a
  subflake is invisible until `git add`ed — `nix build` fails with
  `does not provide attribute 'packages.<system>.<name>'` rather than anything
  pointing at the real cause.
- **Update recipes.** `just update` updates every subflake *and* all root
  inputs; `just update-main` = root inputs only; `just update-input <x>` /
  `just update-subflake <x>` for one. `update-subflake`'s second step, the root
  `nix flake update <x>`, is the one hosts see — per **Submodules + locking**
  (except `lib`, whose root input is `viicslen-lib`: that step matches nothing,
  so follow it with `just update-input viicslen-lib`).
- **omniflake.** 20 dependencies are no longer flake inputs: they are pins in
  [omniflake](https://github.com/fzakaria/omniflake)'s `index.json`, fetched
  lazily at evaluation. The wiring lives in `flakes/lib/omni.nix`
  (`inputs.viicslen-lib.lib.omni`), which exports exactly one function:
  `mkInputs` takes the mapping, the override policy and `ownNixpkgs`, builds
  both loaders internally and resolves the lot. So `flake.nix` holds only data —
  the override policy and the local name → index attribute `mapping` — and no
  loader plumbing; keep it that way. The result is merged into
  `inputs` before `mkFlake`, so `inputs.<name>` and `pkgs.inputs.<name>` are unchanged
  everywhere else and `nix.registry` still lists them (omniflake's loader sets
  `_type = "flake"`). Consequences: `just update-input omniflake` bumps all 20
  at once — home-manager included, so an HM bump is now an omniflake bump —
  and `just update-input disko` no longer resolves; `nix flake metadata` will
  not show them; the index keys on the *repository* name, so
  `vscode-server` is `nixos-vscode-server`, `git-hooks` is `git-hooks-nix`,
  `base16` is `base16-nix`, `jovian` is `jovian-nixos` and `zen-browser` is
  `zen-browser-flake`. `stylix` keeps its name but the index holds
  `nix-community/stylix`, the repo `danth/stylix` was
  transferred to — same project, not a fork. Unification is by
  input *name* at every depth via `omni.mkInputs`, which is where the old
  `follows` lines went — including `systems = systems-linux`, so the
  darwin-stripping workaround reaches every indexed flake. An input stays real
  when something must `follows` it (`nixpkgs`, `systems-linux`), when it
  bootstraps `mkFlake` (`flake-parts`), when it is `flake = false`
  (the index holds flakes only), or when it simply is not indexed.
- **home-manager comes from omniflake, and unifies by self-reference.** The
  override policy is a function of the loader it builds and passes
  `inherit (flakes) home-manager`, so plasma-manager,
  agenix and zen-browser all reach the one copy without home-manager being an
  input. It terminates because overrides apply to a flake's *inputs*, never to
  the flake being loaded — the same shape as omniflake's own `lib.unifyAll`.
  This was only possible after dropping the dead `home-manager` input from
  `flakes/zed` (declared, never read), which was the last `follows` line
  pointing at it. Verified: one rev across ours/plasma/agenix/zen.
- **Unifying nixpkgs silently voids an upstream's binary cache.** `foundations`
  replaces nixpkgs in every indexed subflake at every depth, so a flake whose
  author publishes prebuilt artifacts no longer evaluates to the paths that
  cache holds — the substituter is queried, misses, and nix builds from source
  with no diagnostic beyond a long build. `omni.mkInputs`'s `ownNixpkgs`
  argument is the escape hatch: those index attributes resolve through a
  second loader with nixpkgs dropped from the override set, so they keep
  their author's pin — and still share the one home-manager. Declare it on
  the matching cache entry in
  `caches.nix`, not in `flake.nix` — the routing is derived. The one user today
  is `lantian` → `nix-cachyos-kernel`: xddxdd publishes the CachyOS kernels to
  that attic, and unifying nixpkgs moved the path off it, so every rebuild
  compiled a kernel. Note its `overlays.pinned` does **not** protect you — it
  reads `self.legacyPackages`, which omniflake had already rebuilt against our
  nixpkgs. (`llm-agents-nix` used to be the other one; it is a real input again,
  see CONTEXT.md.)
  Diagnose by comparing store paths, never by reading
  nix.conf: eval the package both ways
  (`nix eval github:<owner>/<repo>/<rev>#packages.x86_64-linux.<pkg>.outPath`
  vs the same attr through a host config) and check the upstream one with
  `nix path-info --store <cache> <path>`. Unpinning costs a second copy of
  nixpkgs in the eval and in that package's runtime closure, so it only pays
  when the upstream cache is actually configured — otherwise it buys nothing.
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
  nixpkgs. This is why `tuicr` keeps its own nixpkgs pin. Fixed globally in the
  `base` preset: `systemd.services.nix-daemon.environment.NIX_CURL_FLAGS =
  "-A Mozilla/5.0"` — fetchurl lists `NIX_CURL_FLAGS` in `impureEnvVars` and
  appends it *after* its own `--user-agent`, so it wins. The value must contain
  no spaces: the builder expands `$NIX_CURL_FLAGS` unquoted. Before the first
  rebuild that carries it, bootstrap the running daemon the same way as the
  GitHub token (`sudo systemctl set-environment NIX_CURL_FLAGS=…` +
  `systemctl restart nix-daemon`).
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
- **`openwiki` carries a generated `package-lock.json`.** The registry tarball
  ships none, so `by-name/openwiki/package-lock.json` is produced by running
  `npm install --package-lock-only --ignore-scripts` against the published
  `package.json` with `devDependencies` and `scripts` stripped (npm errors with
  `Cannot read properties of null (reading 'edgesOut')` if they stay). A bump
  must regenerate it before `npmDepsHash`, or the deps FOD still pins the old
  tree. better-sqlite3 compiles from source here, so budget for that too.
- **Local packages must interpolate the version into the tag.** Write
  `tag = "v${version}"` (or `"v${finalAttrs.version}"`), never a literal
  `rev = "v3.2.1"` — with a literal rev, nix-update rewrites `version` only, so
  the package silently keeps building the old source at the old hash.
- **mkcert has one shared CA: cert plain, key encrypted.** `secrets/mkcert/rootCA.pem`
  is committed as-is (public, must be a store path for `security.pki`);
  `rootCA-key.age` is the secret. The `work` preset wires both into
  `modules.programs.mkcert.rootCA`; the module also imports the CA into each
  user's `~/.pki/nssdb`, which is the only store Chromium/Electron read.
  `CAROOT` is set session-wide, so user-side `mkcert` calls issue from it too.
  See `modules/nixos/programs/mkcert/CONTEXT.md`.
- **Binary caches are declared once, in `caches.nix`.** One entry per cache
  (`url`, `key`, `scope`, optional `ownNixpkgs`); the `base` and `desktop`
  presets call `caches.substituters <scope>` / `caches.trustedKeys <scope>`, so
  add a cache there, never in a preset. `scope = "desktop"` is what keeps the
  bleeding-edge `nixpkgs-wayland` cache and its overlay off headless/WSL hosts —
  don't promote one to `"base"` or they recompile the whole Wayland closure.
  `ownNixpkgs` lists the omniflake index attributes that cache serves, and
  `flake.nix` passes those to `omni.mkInputs` as `ownNixpkgs`, so that routing
  needs nothing beyond the declaration. Any new cache still needs `just
  sync-caches` (next bullet), or every eval fails the drift check. Caches from
  a *subflake's* own `nixConfig` (niri) are separate and still appear in the
  merged `nix.conf`. A cache added here is not
  in the running daemon's `nix.conf` until a rebuild, so the first rebuild that
  needs it passes `--option extra-substituters <url> --option
  extra-trusted-public-keys <key>`.
- **A flake's `nixConfig` cannot be computed.** Both the set and every value
  must be literal: a `let … in` there fails with `expected a set but got a
  thunk`, and even a literal set with a computed value fails with `flake
  configuration setting 'extra-substituters' is a thunk`. So the root
  `flake.nix` cannot import `caches.nix` for its `nixConfig` — that block is a
  hand-kept copy, and `caches.nix` guards it by `readFile`ing `./flake.nix` and
  failing the eval with the missing URLs (plain text, no IFD, no cycle). Two
  further limits: it is *generated* by `just sync-caches` (which imports
  `caches.nix` with `checkDrift = false`, or the assertion would block the
  recipe that clears it) and spliced between the `# BEGIN/END generated`
  markers, so edit `caches.nix` and re-run rather than touching the block;
  `nixConfig` is also *ignored* unless the caller passes
  `--accept-flake-config` (warns `ignoring untrusted flake configuration
  setting` even for a user in `trusted-users`, and `accept-flake-config`
  defaults to false), and turning that on globally would let any flake you
  build add its own substituters *and* trusted keys — so don't. The presets are
  what actually configure these hosts; the flake `nixConfig` is only for
  building this flake on a machine that has not been rebuilt yet.
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
- **`mkIf false` is still a definition.** A home-manager module that writes
  `programs.niri.settings.… = mkIf cond {…}` fails on a host where the niri
  module is not imported at all (`wsl`), with `The option … programs.niri does
  not exist` — the module system rejects the *path* before it looks at the
  condition, and a `mkIf (options.programs ? niri)` wrapper is no different.
  Gate on option existence with `optionalAttrs (options.programs ? niri) {…}`
  as a separate `mkMerge` element, which removes the path entirely. The shell
  modules (`caelestia`, `exo`, `noctalia`) and `t3code` do this.
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
  into the store (effective-html is 22M for 148K of skills). `just vendor-skills
  <owner/repo> [skill|--all]` shells out to `gh skill install --dir` (preview
  command, `gh skill`/`gh skills`) — naming a skill (or its in-repo path) takes
  just that one, `--all` takes the collection, neither prompts. `gh` allows only
  one name per run and rejects `--all` beside it, so a subset means repeating the
  recipe. It drops them in
  `hosts/_shared/presets/personal/ai/skills/`; `just update-skills` re-pulls
  every one, `just skills` lists them with their origin. There is no manifest:
  `gh` records `github-repo`/`github-path`/`github-ref`/`github-tree-sha` in
  each skill's own **SKILL.md frontmatter**, which is what `update` and `list`
  read back. Consequences: a skill written here by hand has no such metadata, so
  `update` warns and skips it (harmless — but don't hand-edit a vendored
  `SKILL.md`, the next update overwrites it; patch it via `patchSkill` instead);
  there is no `gh skill uninstall`, so retiring a collection is `rm -rf` on the
  directories `just skills` attributes to it; and **`git add` the result before
  evaluating** — the flake source is `git+file://`, so untracked skills are
  invisible to `nix eval` and to a rebuild, and the failure looks like the skill
  silently not existing. The recipes `git add` for you.
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
  because the root `follows` it. Only `systems` reaches the root lock, and the
  recipe's second step does not carry it: run `just update-input viicslen-lib`
  (**Update recipes** above).
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
  `modules.programs.ai`'s `integrations/superset.nix` and
  `modules.programs.herdr.enableClaudeIntegration`. Hook lists for the same
  event concatenate, so modules never need to know about each other.
  Claude Code itself, and the mempalace/ponytail/superset hook installers,
  rewrite that file at runtime, so those edits land in `settings.json.backup`
  and are dropped on the next activation. Change settings in Nix, not in the TUI.
  **When an upstream tool ships its hooks as a Claude plugin, enable the plugin
  instead of declaring the hook block** — `modules.programs.claude-code`'s
  `marketplaces` + `plugins` get the hooks *and* that repo's skills for two
  lines, and survive the tool's own installer being unable to write the symlink.
  `mempalace@mempalace` is the worked example.
- **worktrunk owns worktrees and their tmux sessions; workmux is imported but
  off.** `wt` creates under `../.worktrees/<repo>/<branch>`, the `wt tmux`
  alias opens a session named `{{ repo }}@{{ branch | sanitize }}`, `pre-remove`
  kills it, and `prefix + W` opens `wt-dashboard` — an fzf popup over
  `wt list --format=json` (`modules/home-manager/programs/worktrunk/dashboard.sh`)
  that derives the same session name in jq. `checks.worktrunk-tmux` pins all
  of that and asserts workmux stays disabled (`users/neoscode` sets
  `modules.programs.workmux.enable = false`); the module, its
  `worktree-column-width.patch` and its CONTEXT stay in place for a re-enable,
  but its Claude plugin and vendored skills are gone from the personal AI
  preset and would need re-adding. Don't kill a tmux session from inside a
  `wt` hook without checking `#S` first — killing the session `wt` runs in
  aborts the removal half-way; `worktrunk-kill-session` and the dashboard's
  `leave` are the two guards. See
  `modules/home-manager/programs/{worktrunk,workmux}/CONTEXT.md`.

- **A subflake's home-manager wrapper must forward `osConfig` explicitly.**
  `flakes/dms/flake.nix` wraps its module as
  `{config, lib, pkgs, options, ...}: import ./hm.nix {inherit config lib pkgs options inputs;}`.
  That forward list is exhaustive, so an `osConfig` the module needs never
  arrives and an `osConfig ? {}` fallback inside absorbs the loss in silence —
  the gate reads the default and the module stays fully enabled. Bit once
  wiring `modules.desktop.shell`: dms ignored the selection while nilastia also
  came up. Check the wrapper before trusting any gate a subflake HM module
  reads off the NixOS config.
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
- **A remote (HTTP) MCP backend takes its credential from a header, not a
  wrapper.** `gateway.yaml` is generated into `/nix/store`, so a literal token
  in `mcps.<name>.headers` is world-readable. Instead write
  `headers."X-Foo" = "\''${VAR}"` — mcp-gateway expands
  `''${VAR}`/`''${VAR:-default}` in `headers` and `env` (nothing else;
  `http_url` is *not* expanded) — and put `VAR=…` in an agenix **dotenv**
  secret fed to the unit:
  `systemd.user.services.mcp-gateway.Service.EnvironmentFile = "%t/agenix/<name>";`.
  That is how `google_stitch` gets its `X-Goog-Api-Key`.
  **Not `gateway.settings.env_files`**: home-manager's agenix reports
  `age.secrets.<n>.path` as the *literal* `''${XDG_RUNTIME_DIR}/agenix/<n>` for a
  shell to expand, and the gateway's loader expands only `~`, so it skips the
  unresolved path in silence. The variable then stays unset and `expand_string`,
  having no default, substitutes the **empty string** — the backend still starts
  and still lists its tools, because `initialize` and `tools/list` are usually
  ungated, and only `tools/call` comes back 401. systemd's `%t` is
  `XDG_RUNTIME_DIR`, and an `EnvironmentFile` without a `-` prefix makes a
  missing secret fail the unit instead of serving an empty credential.
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
- **CONTEXT.md** — the one in the directory you changed, when the change makes
  its story wrong. No file there yet and the change has a story? Start one.
- **AGENTS.md (this file)** — update when you discover a new gotcha, add or
  rename a preset/subflake, or change a workflow an agent must follow. Keep it
  accurate over exhaustive; verify a claim (that a file, flag, or recipe exists)
  before adding it.
