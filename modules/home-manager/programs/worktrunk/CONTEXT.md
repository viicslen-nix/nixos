# CONTEXT

Why `modules.programs.worktrunk.tmux` is a session per worktree plus an fzf
popup, and what it replaced.

## worktrunk alone again

For a week in September 2026 workmux sat on top of worktrunk as the tmux and
agent layer (`../workmux/CONTEXT.md` keeps that story). Only its worktrees
dashboard was actually used, and the two tools kept tripping over who closes a
session — a removal started from the dashboard killed the session hosting it,
twice, in two different ways. The workmux module stays importable but
`users/neoscode` sets `enable = false`; its Claude plugin and the six vendored
skills went with it, since their instructions run a `workmux` that is no longer
on PATH.

## The session is `{{ repo }}@{{ branch | sanitize }}`

Three places derive the name and `parts/checks.nix` pins them together: the
`tmux` alias creates it, `pre-remove` kills it, and `dashboard.sh`'s jq derives
it for the mux column and the close/remove bindings. Qualified by repo so two
repos' `main` do not collide. `sanitize` is worktrunk's filter — `/` and `\`
become `-` — which is also why the worktree directory's basename equals it
under `../.worktrees/<repo>/`; t3code's `t3code-<hash>` directories are the
exception, hence the `branch → dir` display.

Targets are always `=name`: a bare tmux target prefix-matches, so `repo@feat`
would resolve to `repo@feat-x`.

## `pre-remove` never kills its own session

The pre-workmux hook killed unconditionally. From a shell inside the session
being removed that kills `wt` in the middle of its hooks — the same failure
workmux's `close` had, and what left worktrees half-removed. `worktrunk-kill-session`
compares the target with `#S` and skips when they match; the dashboard's
`leave` switches the client to another session first, so a removal from the
popup still cleans up fully. A removal from a shell inside the worktree's own
session leaves that session alive on a deleted cwd — chosen over aborting the
removal. It stays `|| true` because `pre-remove` blocks.

## The dashboard is fzf, not a TUI

`wt list --format=json` already carries everything workmux's worktrees tab
showed — status symbols, divergence from main, diff size, PR number and checks
(with `--full`), the dev-server URL — so the dashboard is a jq render of it
inside fzf, which supplies the table, the git-log preview, filtering and the
key bindings. Hidden tab fields (branch, path, session, url) feed the bindings;
`--with-nth 5` shows the rendered row. Two details:

- `reload-sync` on `start`: the fast list (~0.5 s) appears at once and the
  `--full` one (~1.7 s, forge round-trips) replaces it when ready. `ctrl-r`
  refetches.
- `NO_COLOR=1` on the `wt list` call: otherwise `display.statusline` carries
  OSC 8 hyperlinks whose BEL byte is invalid JSON and jq refuses the document.
  The script reads schema 2 (`.items`), which `list.json-schema = 2` selects.

The layout follows the width, because the portrait monitor is a real
terminal here: below `$narrow` columns the preview moves under the list
(fzf's `<SIZE(...)` alternative layout) and the row gets the whole width;
above it the row gets ~55%. The jq shrinks the branch column to fit and drops
the diff and commit columns under 90 columns of list, and a `resize` reload
re-renders on rotation. The width comes from `stty size </dev/tty`, minus the
two border columns — not from `FZF_COLUMNS`, which fzf exports as `0` to the
`start` reload because it has not laid itself out yet, and not from
`tput cols`, which answers 80 when stdout is the reload pipe. That `0` is what
rendered the table at the 20-column minimum inside a full-width popup.

It is a popup, not a window: `enter` ends in `become(wt tmux …)`, whose
post-switch script runs `tmux switch-client`, after which the process exits and
the popup closes with it. Column widths count codepoints, so the jq `width`
adds one for each emoji status symbol (🤖, 💬) by hand.

## `{% raw %}` in the alias

The alias body is rendered once by the alias engine (which substitutes
`{{ args }}`), and the inner template has to survive that pass to be rendered
again by `wt switch` with the worktree in context. `--no-cd` because the
post-switch script handles navigation; `--execute` replaces the `wt` process,
so nothing runs after it.
