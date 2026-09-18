# CONTEXT

The `neoscode` home-manager user. Covers what belongs in this file at all, the
ssh ControlMaster keep-file and the Wayland re-attachment prelude in the shell
configs.

## Every host loads this file

It is applied to headless `wsl` and the base+desktop handheld alike, so only
identity and shell-level config sit here unconditionally. Work-only items
(intelephense licence, kubectl/sail/deployer aliases, the cloudflared
`ProxyCommand`) live in the `work` preset's `home.nix`; the avante key in
`personal`. GUI items stay here but are gated on
`osConfig.modules.presets.desktop.enable`: the `defaults` slots, the 1Password
autostart, and the ghostty/wezterm/vivaldi `enable`s. The imports themselves
cannot be conditional, so the gate is on each module's `enable`.

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
