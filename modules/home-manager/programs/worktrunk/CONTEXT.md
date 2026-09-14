# CONTEXT

Why `modules.programs.worktrunk.tmux` delegates to workmux, and what it
replaced.

## The division of labour

worktrunk and workmux overlap almost entirely — both create worktrees, bind
them to tmux, and own merge/remove. They are split here by which half each is
*better* at, not by preference:

- **worktrunk creates and tears down.** It keeps `wt switch`, the LLM commit
  generation, the `wt merge` pipeline and the aliases.
- **workmux attaches and observes.** It owns the tmux target and the agent
  status icons, dashboard and sidebar.

The split is by capability, not territory: both tools now create into
`../.worktrees/<repo>/<branch>`, so a worktree made by either is in the same
place and carries the same handle. What worktrunk keeps is the richer lifecycle
— ten hooks to workmux's three, commit generation, the merge pipeline.

workmux finding worktrunk's worktrees is not a coincidence of layout: it
resolves from `git worktree list` — basename first, then branch — and never
consults its own `worktree_dir` on the read path, so it would see them wherever
they sat. The shared path matters for *creation*, which is why the two
templates are pinned against each other in `parts/checks.nix`.

## What the `tmux` option used to be

It carried two hand-rolled shell scripts, both deleted:

- `postSwitchScript` — created-or-switched a tmux session per worktree. Now
  `workmux open`, which does the same and additionally backfills the
  `workmux.worktree.*` git config so the dashboard and `resurrect` can see the
  worktree.
- `tmuxWorktreePickerScript` — a ~100-line `television` picker bound to
  `prefix + W`, offering switch and delete. Now `workmux dashboard -t worktrees`,
  whose worktrees tab is a strict superset: jump, close, remove, add, filter.

## `open "{{ branch }}"`, not the directory name

The alias passes the raw branch, not `{{ repo }}@{{ branch | sanitize }}`.
Handle matching only works for non-primary worktrees — the primary worktree's
directory is plain `repo`, so a `repo@main` handle matches nothing and the
lookup has to fall through to the branch. Branch matching works for both.

The `{% raw %}` wrapping is unrelated to workmux and must stay: the alias body
is rendered once by the alias engine (which is what substitutes `{{ args }}`),
and the inner template has to survive that pass to be rendered again by
`wt switch` with the worktree in context.

## `pre-remove` takes no argument

`workmux close` defaults to the current directory, and `pre-remove` already runs
inside the worktree being removed. It stays `|| true` because `pre-remove`
blocks — a failed close would otherwise abort the removal.
