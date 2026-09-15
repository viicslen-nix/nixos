# CONTEXT

Why `modules.programs.t3code` rebuilds the stock package before installing it,
and why the server is declared by hand.

## `withConnect` — the two gaps in every packaging of t3code

`cfg.package` is the *stock* t3code; both fixes are applied in the module, so
pointing the option at another packaging of it (nixpkgs, or
numtide/llm-agents.nix, which has the same two gaps) still gets them.

1. **A source build bakes in no cloud config.** `scripts/lib/public-config.ts`
   feeds the repo's `.env` into both vite builds, so without it the server and
   the web client carry empty Clerk/relay literals and the client's
   `hasCloudPublicConfig()` goes false, which is what strips the T3 Connect
   block from Settings › Connections. (The `connect` subcommand still registers
   either way — it just has no relay to reach.) Upstream's documented fix for
   source builds is to copy `.env.example` — public identifiers, not secrets —
   into place, so take that verbatim rather than restating the values here.
   Costs a full rebuild of the pnpm/electron tree.
2. **The relay client T3 Connect tunnels through** is the one piece not covered
   by `.env`: upstream downloads its own cloudflared on first `t3 connect
   link`. `cloudflaredPackage` points it at the Nix one instead.

Both land on the unwrapped derivation — the only layer whose shape is the same
across packagings — and the outer wrapper just execs it, so the env var
survives.

## `finalPackage`, and why the desktop app comes from it

The desktop app has to come from this same derivation. Installing a stock
`t3code-desktop` alongside it silently splits the two: the CLI gets T3 Connect
and the app — which spawns its own backend out of its own output, not the
`serve` unit — does not. `out` is the CLI; the Electron app is the `desktop`
output, and it is only useful on a graphical host.

## The systemd unit is written here, not by `t3 service install`

Upstream's own `t3 service install` writes a unit that runs a self-updating
launcher, which npm-installs new versions over itself — the server is declared
directly instead. Starting it is also what provisions a `t3 connect link` that
is still pending.

`t3 connect login`/`link` persist their authorization in `~/.t3`, alongside the
project database — losing it means re-authorizing every boot, hence the
persistence entry.

## t3code cannot join the shared worktree tree

worktrunk and workmux are both pointed at `../.worktrees/<repo>/<branch>`
(see `../workmux/CONTEXT.md`). t3code is deliberately left out of that, because
its worktree location is hardcoded:

```ts
// apps/server/src/vcs/GitVcsDriverCore.ts
const worktreePath = input.path ?? path.join(worktreesDir, repoName, sanitizedBranch);
// worktreesDir = join(baseDir, "worktrees"), baseDir = T3CODE_HOME ?? ~/.t3
```

There is no setting, no `t3.json` key and no per-project override for it — the
worktree-adjacent settings that do exist (`newWorktreesStartFromOrigin`,
`defaultThreadEnvMode`, `runOnWorktreeCreate`) are behavioural. The RPC input
carries an optional explicit `path`, but every first-party caller passes `null`
and no UI surfaces it.

The only lever is `--base-dir` / `T3CODE_HOME`, and it is the wrong one: it
relocates the whole data directory — `userdata`, `caches`, the auth tokens and
project database this module persists as `.t3` — and it names the *parent* of
`worktrees`, so aiming it at the checkout directory would both collide with the
`worktrees` repo living there and scatter `userdata` beside the clones.

The shape already agrees (`<root>/worktrees/<repo>/<branch>`, slashes in the
branch turned to dashes); only the root differs. Leave it at `~/.t3`.
