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

## Keybinds follow the shell, and the shell owns them

The two shells deliver binds by different routes, which is why they never
collide. dms rewrites niri's `config.kdl` through its `niri.includes` hack, so
its binds live in a generated `dms/binds.kdl`; that hack is gated off when
another shell runs. Nilastia instead contributes to
`programs.niri.settings.binds` from its own home-manager module, under the same
`mkIf` as the shell itself — so the keys exist only while it is selected, and
`flakes/niri/config/binds` never learns a shell name.

That placement is the point: a bind belongs to the thing it drives. A third
shell adds its own binds in its own module and touches nothing here.

Nilastia's five (`Mod+Space` launcher, `Mod+G` dashboard, `Mod+Shift+Q` session,
`Mod+Shift+N` nexus, `Mod+Alt+L` lock) were chosen from keys the base niri
config leaves free, so no `mkForce` is involved — if a future bind collides the
module system will say so rather than silently pick a winner.

`Mod+Shift+S` is deliberately *not* taken for nilastia's screenshot picker: the
existing menu in `flakes/niri/config/binds/screenshots.nix` works under either
shell, and overriding a working bind to duplicate it buys nothing.
