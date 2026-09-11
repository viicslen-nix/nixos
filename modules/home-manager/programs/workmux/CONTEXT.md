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

## `worktree_dir` is deliberately unset

It only affects `workmux add`, and worktrunk owns worktree creation here (see
`../worktrunk/CONTEXT.md`). Setting it would imply workmux creates worktrees
too, which would put them somewhere worktrunk does not look.
