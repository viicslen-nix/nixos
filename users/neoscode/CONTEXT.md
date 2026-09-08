# CONTEXT

The `neoscode` home-manager user. Covers the ssh ControlMaster keep-file and the
Wayland re-attachment prelude in the shell configs.

## `.ssh/controlmasters/.keep`

ssh refuses to open a control socket if the `ControlPath` directory is missing,
which breaks any host using `ControlMaster`. The empty keep-file exists only so
the directory does; it pairs with the `ControlPath` declaration in
`programs.ssh.settings`.

## `reattachWayland`

Superset builds its PTY env from a scrubbed login-shell snapshot, which carries
no `WAYLAND_DISPLAY` — so `wl-copy`/`wl-paste`, and with them Claude Code's image
paste, have no compositor to talk to. The prelude points them back at the
session socket when one exists.
