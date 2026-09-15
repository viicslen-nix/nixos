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
bare worktree directory basename — which, now that both tools create
`../.worktrees/<repo>/<branch>`, is the branch.

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
`PostToolUse`/`Notification`/`Stop` hooks with no Nix hook block at all. The
plugin's hook commands invoke a bare `workmux`, which is why the module puts the
package in `home.packages` rather than only referencing its store path.

The plugin manifest declares hooks only — it carries no skills, so
`setup --skills` is the other half of `setup` that has to be replaced rather
than simply skipped. The six skills are vendored into the personal AI preset
instead (`just vendor-skills raine/workmux --all`), which is what reaches
opencode, antigravity and copilot as well; the plugin would only ever have
served Claude Code. Running `setup --skills` writes them as real directories
under `~/.claude/skills/`, where they collide with the generated symlinks on the
next activation — remove them rather than letting home-manager rename them to
`<name>.backup`.

Status tracking itself needs none of the above wiring: `set-window-status`
resolves its target from the pane alone and has no worktree or window-ownership
concept, so it reports correctly from any tmux window.

## `tmux.enable` — the keys, and why these three

workmux installs no tmux bindings of its own; upstream only documents suggested
ones. The three here are its suggestions with two deviations.

`prefix + t` rather than upstream's `C-t`, because the only control keys bound
in this config are `C-h C-l C-n C-o C-p C-Space C-z` and their arrow variants,
so there is no chord pressure to escape — and `t` sits better beside `W`, the
dashboard key in the worktrunk module. What it displaces is tmux's built-in
`clock-mode`. Lowercase matters: `T` is the sesh picker.

`L` is upstream's key and displaces tmux's default `switch-client -l`, which is
free to take because `tmux.conf` already binds `^` to exactly that.

The `-s` on the sidebar is the deviation that matters, and `parts/checks.nix`
pins it: without it the sidebar is global, and enabling it adds a pane to every
window of every session plus a hook that does the same to new ones — including
sessions holding no worktree at all.

Upstream also suggests a `C-s` dashboard binding; it is deliberately absent,
since `W` already opens the dashboard and its tabs switch from inside.

## Hooks — `post_create` and `pre_remove: []`

workmux has three hooks to worktrunk's ten — `post_create`, `pre_merge`,
`pre_remove`, all blocking, with no background `post_*` equivalent. Note the
naming inverts: workmux's `post_create` and worktrunk's `pre-start` fire at the
same moment, after the worktree exists and before the window opens.

`post_create` is deliberately unset. It used to run `direnv allow`, because
direnv keys its allow list by path and a new worktree's `.envrc` is
unauthorized even though the file is tracked. The problem is that this is the
*global* hook: it fired in every repo, so it added whatever `.envrc` the
checked-out branch happened to carry to direnv's allow list with no prompt, and
a branch that edits `.envrc` then gets it executed on the next shell entry.

direnv approval is per project instead, the shape worktrunk already uses.
worktrunk-created worktrees — the overwhelming majority — are covered by its
project-scoped `pre-start`, and a repo that wants the same for `workmux add`
carries `post_create` in its own `.workmux.yaml`. Unlike `pre_remove` below,
dropping `post_create` leaves no upstream default behind.

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
`git worktree list` and ignore it entirely. `../.worktrees/{project}` collects
every repo's worktrees under one directory beside the checkouts, rather than
upstream's default of a `<project>__worktrees` sibling per repo, which scatters
one such directory next to each clone. `{project}` is the project root's
directory name and may sit anywhere in the path, not just at the front.

The leading dot is not cosmetic: the checkouts live in `~/Development`, which
already holds a repo *named* `worktrees` (`viicslen/worktrees`). Undotted, every
worktree would be created inside that project's working tree, showing up as
untracked directories in it — its `.gitignore` does not cover them.

worktrunk's `worktree-path` is pointed at the same tree, so both tools create
`../.worktrees/<repo>/<branch>` and a worktree is in the same place whichever one
made it. The two templates are pinned separately in `parts/checks.nix` because
the syntaxes differ — worktrunk takes a full per-branch path, workmux only a
parent whose leaf is always the handle — so they cannot be compared directly and
would otherwise drift apart silently.

That shared layout is why `window_prefix` stays empty. The handle is the leaf
directory, which is now the bare branch, so sessions read `feature-x` and the
primary worktree keeps its clean `myrepo`. Setting `window_prefix` to
`"{project}@"` would qualify the feature sessions as `myrepo@feature-x` but
double the primary into `myrepo@myrepo`, since a static prefix cannot tell the
two apart. Nothing else recovers the qualifier: a `@` reaches a session name
only through the worktree directory name, and every workmux path that names a
directory slugifies it — `--name 'myrepo@feat'` lands at `myrepo-feat`, and
`--target-name` is slugified *and* re-prefixed.

## `dashboard.worktree_columns` — and what it cannot fix

The Worktrees tab's `project` column shows the worktree *handle*, not the
project, on every worktree but the primary — so it just repeats the first half
of `worktree`. Dropping it is the whole reason this key is set; the rest of the
list is upstream's default order. The key needs workmux >= 0.1.260.

`preview_size` trades preview height for table rows. At the default this repo
shows 16 worktrees against the 25 it has, so most sit below the fold; at 25 it
shows 28. `sort_mode` is *not* a lever despite appearing in the same block — it
seeds the agent list only, and the Worktrees tab persists its own
`worktree_sort_mode` from the `s` key, so setting it in config changes nothing.

It does **not** widen the branch. `worktree` renders as `<handle> →<branch>` and
is capped at roughly 25 columns: rendering the tab with `worktree_columns:
[worktree]` alone in a 160-column pane still truncates. The freed width goes to
`git`, not to `worktree`. So for a worktree whose handle is already long — every
t3code one is `t3code-<8 hex>` — the branch is always cut off, and no
configuration recovers it. The tab is a status view, not a worktree picker.
