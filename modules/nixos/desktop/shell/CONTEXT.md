# Desktop shell selection

`modules.desktop.shell` picks which shell autostarts in a graphical session.
Today that is `dms` (DankMaterialShell, a subflake) or `nilastia` (a Caelestia
fork for niri), plus `none`.

## Why the compositors don't name the shell

niri and hyprland both used to run
`systemctl --user start dms-session.target` from `spawn-at-startup`. That put
the shell's name in two compositor configs, so adding a second shell meant
teaching both compositors about the choice.

They now start `desktop-shell.target`, which is declared here and is
deliberately empty. Each shell binds its own service to it with
`PartOf`/`WantedBy`, and only the *selected* shell's service is ever defined —
so the target pulls in whatever exists, and the compositors never learn a shell
name. `none` starts the target and nothing follows.

Adding a third shell is therefore: a home-manager module that binds its service
to `desktop-shell.target`, plus a value in the enum. No compositor change.

## The trap: a subflake's home-manager wrapper must forward `osConfig`

`flakes/dms/hm.nix` gates itself on `osConfig.modules.desktop.shell`. That
silently did nothing at first, because `flakes/dms/flake.nix` wraps the module
as `{config, lib, pkgs, options, ...}: import ./hm.nix {inherit config lib pkgs
options inputs;}` — an explicit forward list that did not include `osConfig`.
The `osConfig ? {}` fallback inside `hm.nix` then made every host look like
`shell = "dms"`, and dms stayed fully enabled while nilastia also came up.

Nothing fails loudly here: the wrapper drops the argument, the fallback absorbs
it, and both shells run. If a subflake's home-manager module needs to read the
NixOS config, check that its wrapper forwards `osConfig` before trusting the
gate.

## The greeter is not part of this

`programs.dms-greeter` (dank-greeter) is configured in the `desktop` preset and
stays on whichever shell is selected — it runs before the session, not inside
it. Nilastia ships no greeter, so switching to it does not cost the login
screen.

## Keybinds are not switched

dms rewrites niri's `config.kdl` through its `niri.includes` hack; that is gated
off when another shell runs, so niri falls back to the binds in
`flakes/niri/config/binds`. Nilastia's own IPC binds are not wired up — it
exposes them as `quickshell -c … ipc call …` spawns, and they would have to be
added to the niri config to be reachable.
