# CONTEXT

Why `modules.programs.tmux` pins the pane shell.

## `shell = getExe pkgs.nushell`

The pane shell is pinned instead of inherited from `$SHELL`: the account shell
is zsh (Superset wraps it), and a stale `$SHELL` makes tmux fall back to
`/bin/sh`.
