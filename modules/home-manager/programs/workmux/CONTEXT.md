# CONTEXT

Why `modules.programs.workmux` looks the way it does, and where its package
and its Claude Code hooks come from.

## The package is `pkgs.inputs.llm-agents.workmux`

workmux is not in nixpkgs. Upstream ships its own `flake.nix`, but adding
`github:raine/workmux` as an input would duplicate a package this flake already
reaches: `numtide/llm-agents.nix` packages it, and that input is already here.
The llm-agents derivation is also the better of the two — upstream's pins
`version` to `self.shortRev`, while llm-agents carries a real version and
installs the shipped skills to `share/workmux/skills`.

It substitutes from `cache.numtide.com`, which `caches.nix` already declares, so
there is no from-source Rust build. Note that omniflake is *not* involved: the
`llm-agents` input deliberately leaves `nixpkgs` un-overridden, which is what
keeps that cache hitting.

## `mode: session` + `window_prefix: ""`

These two exist to make workmux's tmux target names identical to the ones
worktrunk's `worktree-path` produces. With `mode: session` the target is a
session rather than a window, and with an empty prefix the session name is the
bare worktree directory basename — `repo@branch`, matching
`../{{ repo }}@{{ branch | sanitize }}`.

That naming is what lets workmux *adopt* a session worktrunk already created
instead of opening a rival one: a worktree carrying no `workmux.worktree.*` git
config is treated as `Legacy`, so `workmux open` checks whether the target
session exists and switches to it. Restore the default `wm-` prefix and every
`wt tmux` gets a second, duplicate session.

Session mode has a second benefit that the alias depends on: `workmux open` run
*outside* tmux fails in window mode (it cannot pick a parent session) but
succeeds in session mode.

## `nerdfont: true`

Not cosmetic. On first run workmux probes interactively for nerdfont support
and then persists the answer to `~/.config/workmux/config.yaml` — which is a
read-only store symlink here. Declaring the value skips the probe. The same
first run also offers to install status hooks and skills; both are declined
permanently by the plugin wiring below.

## Status hooks come from the Claude plugin, not `workmux setup --hooks`

`workmux setup --hooks` merges its hooks into `~/.claude/settings.json`. That
file is a home-manager store symlink, so the write either fails or lands in
`settings.json.backup` and is dropped on the next activation — the same trap
mempalace and superset hit.

Upstream also publishes the identical hooks as a Claude Code plugin, so the
personal AI preset enables `workmux-status@workmux` from the `raine/workmux`
marketplace instead. That brings the `SessionStart`/`UserPromptSubmit`/
`PostToolUse`/`Notification`/`Stop` hooks *and* the six shipped skills with no
Nix hook block at all. The plugin's hook commands invoke a bare `workmux`, which
is why the module puts the package in `home.packages` rather than only
referencing its store path.

Status tracking itself needs none of the above wiring: `set-window-status`
resolves its target from the pane alone and has no worktree or window-ownership
concept, so it reports correctly from any tmux window.

## Hooks — `post_create` and `pre_remove: []`

workmux has three hooks to worktrunk's ten — `post_create`, `pre_merge`,
`pre_remove`, all blocking, with no background `post_*` equivalent. Note the
naming inverts: workmux's `post_create` and worktrunk's `pre-start` fire at the
same moment, after the worktree exists and before the window opens.

`post_create` runs `direnv allow` because direnv keys its allow list by path, so
a new worktree's `.envrc` is unauthorized even though the file is tracked. It is
guarded with `test -f .envrc` because this is the *global* hook and fires for
every repo, not just the ones using direnv. It reaches only worktrees workmux
itself creates; worktrunk-created ones are covered by its own project-scoped
`pre-start`.

`pre_merge` is dormant — worktrunk owns merging.

`pre_remove` is the exception, and the reason it is pinned to an empty list
rather than left out: its default auto-detects Node projects and fast-deletes
`node_modules`. That path is reachable from the dashboard bound to `prefix + W`
— `r` removes a worktree and `R` sweeps several — and a removal taken that way
bypasses worktrunk's own `pre-remove`, so the project hooks that clean up after
a worktree never run. Emptying the list keeps `wt` the only thing that deletes a
worktree. Note that *omitting* the key does not disable the hook; it restores
upstream's default.

## `worktree_dir` — sibling of the repo, not inside it

Only `workmux add` reads this; `open`, `list` and `resurrect` all resolve from
`git worktree list` and ignore it entirely. `../worktrees/{project}` collects
every repo's worktrees under one directory beside the checkouts, rather than
upstream's default of a `<project>__worktrees` sibling per repo, which scatters
one such directory next to each clone. `{project}` is the project root's
directory name and may sit anywhere in the path, not just at the front.

It cannot be made to match worktrunk's `../{{ repo }}@{{ branch | sanitize }}`
exactly, and the difference is structural rather than cosmetic: `worktree_dir`
names a *parent directory* and the leaf is always the handle, so there is no
per-branch template. `worktree_prefix` does not close the gap either — it takes
no `{project}` (the literal `{project}-` slugifies to `project-`), and slugify
strips the `@` regardless, so `myrepo@` becomes `myrepo-`.

Both layouts sit beside the repo rather than inside it, and workmux reads both,
so they coexist. The one visible seam is session naming: a worktrunk worktree's
handle is `repo@branch` and a workmux one's is the bare branch, so their
sessions read `repo@feature-x` and `feature-x`. Closing that would mean pointing
worktrunk at `../{{ repo }}__worktrees/{{ branch | sanitize }}` and setting
`window_prefix = "{project}@"` — don't do it piecemeal, because that prefix
applied to worktrunk's current layout produces `repo@repo@branch` for every
worktree that already exists.
