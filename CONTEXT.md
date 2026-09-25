# CONTEXT

The story behind decisions at the root of this repo — the things a diff does
not explain. Rules and workflows live in [AGENTS.md](./AGENTS.md); this file is
why the code looks the way it does.

## An index entry can freeze, and bumping omniflake won't unstick it

`llm-agents-nix` sat on one rev across four consecutive `Update index` commits
while upstream shipped several package bumps a day. `just update-input
omniflake` was a no-op for it. Check before assuming a stale dependency is your
lock's fault — no fetch, no eval:

```bash
curl -sL "https://raw.githubusercontent.com/fzakaria/omniflake/$(jq -r .nodes.omniflake.locked.rev flake.lock)/index.json" \
  | jq '."<attr>".locked'
```

The fix is to make it a real input again, which is what `llm-agents` now is.
Two things learned doing it:

- **Don't hand-pin its nixpkgs to hold onto the upstream cache.** An input you
  say nothing about is locked from the *dependency's own* `flake.lock`, and
  `nix flake update <x>` re-reads that lock, so the author's rev tracks itself.
  Verified bare and with a sibling `follows`, at first lock and across an
  update. The forward jump described in AGENTS.md under "Removing an
  `inputs.<x>.nixpkgs.follows` does not restore the old pin" is specific to
  *removing* an override that was already locked.
- **Restore the loader's `systems = systems-linux`**, as
  `inputs.<x>.inputs.systems.follows = "systems-linux"`. Coming out of the
  index loses it.

Verify with store paths: `packages.x86_64-linux.<pkg>.outPath` through
`github:<owner>/<repo>/<rev>` must equal the one through
`(builtins.getFlake "git+file:///etc/nixos?submodules=1").inputs.<x>`, then
`nix path-info --store <cache> <path>` to confirm the cache has it.

## `flake.nix` — the omniflake wiring

`omniflake` is ~12k pinned flakes behind one input; the `mapping` in `outputs`
says which of this repo's dependencies come through it. Bump with
`just update-input omniflake`.

Those 20 dependencies come from omniflake's index rather than `flake.lock`, and
are resolved into `inputs` before `mkFlake`. The plumbing lives in
`flakes/lib/omni.nix`; what stays in `flake.nix` is the policy and the list.

`overrides` takes the loader so `home-manager` can unify to the loader's own
copy — that self-reference is what keeps exactly one home-manager in the graph
without home-manager being an input. `systems` is the linux-only list for the
same reason `systems-linux` exists at all. `ownNixpkgs` comes from
`caches.nix`: declaring a cache there is what routes its flakes off the unified
nixpkgs, so nothing has to name them a second time.

`mapping` is local input name -> index attribute; the two sides differ because
the index keys on the *repository* name. Find the right-hand side with
`just omniflake-search <term>`.

## `flake.nix` — inputs deliberately left off our nixpkgs

- **llm-agents** — the agent CLIs (codex, claude-code, copilot-cli,
  antigravity, t3code, …). Leaving `nixpkgs` un-overridden locks it from
  llm-agents' own `flake.lock`, which is what keeps `cache.numtide.com`
  hitting.
- **superset-desktop** — private, and resolvable because `access-tokens` is
  wired in the base preset. Deliberately does not follow nixpkgs: it ships a
  prebuilt AppImage and pins its own nixpkgs for the autoPatchelf inputs.
- **ghostty** — `ghostty.cachix.org` is a configured substituter, and its
  builds are keyed to the nixpkgs ghostty pins. Ours matches it today only by
  coincidence (one day apart), so following would turn every future ghostty
  into a from-source zig build. Costs 7 lock nodes.
- **tuicr** — pinning it to ours forces a cargo re-vendor, and when this was
  decided crates.io 403'd nix's curl User-Agent from here, so the rebuild died
  on `cannot download download-adler2-2.0.1 from any mirror`. That 403 was gone
  by 2026-09, so the pin may no longer be needed. Costs 7 lock nodes.

## `flake.nix` — other input notes

- **ai** follows this flake's `omniflake`, `packages`, `llm-agents` and
  `viicslen-lib` so nothing is locked twice. It absorbed the old `opencode`
  subflake, and it owns `mattpocock-skills` now — bump the skills with
  `just update-subflake ai`, not an `update-input` here.
- **nixvim** — `flakes/neovim` is still a maintained subflake but nothing here
  consumes it; 5556fbc replaced it with nixvim. Re-add as an input when
  something needs it again.
- **systems-linux** is the linux-only systems list, used to strip
  `x86_64-darwin` from transitive flake-parts flakes (nixpkgs 26.11 throws when
  its darwin set is evaluated).

## `flake.nix` — the `parts/` auto-import

Every file under `./parts` is a flake-parts module and is picked up
automatically — drop a new file in to add a concern, no wiring needed.
Non-recursive on purpose: `parts/` is flat, and a nested directory should be
imported by the part that owns it, not silently by the flake root.

## `flake.nix` — the generated `nixConfig` block

nix cannot evaluate this block: a flake config value must be a *syntactic* list
of *syntactic* strings (`Value::isTrivial` forces only
`ExprAttrs`/`ExprLambda`/`ExprList`, so `map …`/`import …` stay thunks, and the
list branch then requires every element to already be `nString`). So it is
generated from `caches.nix` by `just sync-caches`, spliced between the
`# BEGIN generated` / `# END generated` markers; `caches.nix` asserts the two
match and tells you to re-run the recipe when they don't.

The block only takes effect with `--accept-flake-config`; the presets are what
configure the hosts here. This is for building the flake on a machine that has
not been rebuilt yet.

## `caches.nix`

Single source of truth for the extra binary caches this repo trusts. Three
things read the table:

1. `hosts/_shared/presets/{base,desktop}` — `nix.settings.substituters` and
   `trusted-public-keys`, split by `scope`.
2. `flake.nix` — `ownNixpkgs` names the omniflake index attributes that must
   keep their author's nixpkgs pin, because unifying nixpkgs changes the
   derivation hash and voids exactly the cache listed here. Adding a name there
   is all it takes; the loader routing is derived from it.
3. `flake.nix`'s `nixConfig` — generated by `just sync-caches`, because nix
   refuses to evaluate a computed flake config value. `drift` at the bottom
   fails the eval when that generated block is stale.

`scope` is `"base"` (every host, including headless/WSL) or `"desktop"`
(graphical hosts only — see the desktop preset).

`checkDrift = false` skips the `flake.nix` consistency assertion. Only the
generator that *fixes* the drift passes it — otherwise `just sync-caches` would
be blocked by the very error it exists to clear.

nix refuses a computed `nixConfig` outright: the set must be a literal and so
must every value — a `let … in` there fails with "expected a set but got a
thunk", and even a literal set whose values are computed fails with "flake
configuration setting 'extra-substituters' is a thunk". So `flake.nix` cannot
import this file for it, and its `nixConfig` is a hand-kept copy.
`nixConfigBlock` renders the literal nix.conf-shaped text that `just
sync-caches` splices between the markers there. `drift` names anything this
table has that `flake.nix`'s text does not, so the copy cannot rot silently.
`readFile` on a sibling path is plain text — no IFD, and no cycle, since it
never evaluates `flake.nix`.
