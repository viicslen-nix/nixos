# Desktop shell selection

`modules.desktop.shell` picks which shell autostarts in a graphical session.
Today that is `dms` (DankMaterialShell, a subflake), `nilastia` (a Caelestia
fork for niri), `exo` (Material 3, built on Ignis) or `noctalia`, plus `none`.

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

The target is `After` **and** `BindsTo` `graphical-session.target`, and that is
load-bearing. A shell reads `WAYLAND_DISPLAY` from the systemd *user manager*
environment, which the compositor only imports on its way to
`graphical-session.target` — and a service inherits that environment at spawn
time, so starting one second too early is permanent for that process. Exo hit
exactly this: home-manager activation started `desktop-shell.target` at
00:57:10 while niri reached `graphical-session.target` at 00:57:13, and
`ignis init` came up three seconds early with no `WAYLAND_DISPLAY`. It then
raised `DisplayNotFoundError`, **stayed running**, and never restarted — so
`systemctl --user status` reported `active (running)` with no shell on screen
and `NRestarts=0`. `After` alone does not help here, because ordering only
constrains units inside one transaction; `BindsTo` is what refuses the start
outside a session. Diagnose this class of failure by reading
`/proc/<pid>/environ`, not `systemctl show -p Environment` — the latter lists
only what the unit file sets, and an inherited-environment bug leaves it empty
either way.

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

## Exo is not a Nix-native shell, and that shows

dms and nilastia both ship home-manager modules. Exo ships none — no flake, no
`.nix` file anywhere. What it is, structurally, is an [Ignis](https://github.com/ignis-sh/ignis)
config directory plus a set of matugen templates, so it rides as a
`flake = false` input and the real packaging work is done by Ignis's own
home-manager module.

Two consequences worth knowing before editing `modules/home-manager/programs/exo`:

**`programs.ignis.configDir` is deliberately not used.** It resolves to
`xdg.configFile."ignis".source = <dir>`, which links the *directory*, making
`~/.config/ignis` a read-only store symlink. Exo writes inside that directory
at runtime — `user_settings.py` hardcodes
`~/.config/ignis/user_settings.json`, and `matugen/config.toml` sends its
`[templates.ignis]` output to `~/.config/ignis/colors.scss` on every wallpaper
change. Under a directory symlink both writes fail and the shell loses its
settings and its dynamic theming. Setting `xdg.configFile."ignis"` with
`recursive = true` instead links each file individually into a real, writable
directory, so the generated files can sit beside the linked ones. The same
applies to `~/.config/matugen`.

**nixpkgs renamed `swww` to `awww`.** The package Exo wants for wallpapers is
`pkgs.awww`; `pkgs.swww` still resolves through an alias but prints an eval
warning, and the binaries are `awww` / `awww-daemon`, so a unit calling
`swww-daemon` dies with `status=203/EXEC`. Exo also hardcodes `command = "swww"`
in `matugen/config.toml` — a single occurrence, covered by a one-line
`writeShellScriptBin` shim rather than by rewriting a linked config file.

**Exo expects three files it does not ship.** `ignis/user_settings.py` builds an
`OptionsManager`, whose `__init__` calls `load_from_file` unconditionally — no
existence check — and the stylesheets `@use "../colors"` and
`"../preview-colors"`. None of `user_settings.json`, `colors.scss` or
`preview-colors.scss` is in the repo; `exoinstall.py` generates them on first
run, which is why they are also its `protected_files`. The module reproduces
that bootstrap in a `home.activation` entry that only ever *creates* what is
missing, because those files are Exo's own mutable state afterwards.

`colors.scss` is generated in a derivation rather than during activation.
Running Exo's real `matugen/config.toml` would emit ten templates across
`$HOME`, `pkill -SIGUSR1 kitty` and call `gsettings`, and a non-zero exit there
would fail the whole rebuild. The derivation instead feeds matugen a minimal
config holding only the ignis template. Two things it needs: matugen rejects a
config with no `[config]` table, and off a terminal it refuses to pick between
multiple source colors unless given `--prefer`.

**Upstream drift is the live risk.** Exo's README requires Ignis "git/dev", and
Exo's last commit is months behind the Ignis the flake resolves to. Nothing
pins them to each other, so an Ignis bump can break Exo with a Python
traceback rather than an eval error — `journalctl --user -u exo` is where that
surfaces, since a failing `ignis init` just restarts.

Exo also has no lock screen on niri: it themes hyprlock, which is a Hyprland
component, and its own binds reach only Launcher, QuickCenter, PowerMenu and
Settings.

## One keymap across shells

The shells expose different feature sets under different names, but the four
common concepts are bound to the same keys, so the muscle memory survives a
switch. Only one shell is ever enabled, so there is no collision.

| Key | dms | nilastia | exo | noctalia |
| --- | --- | --- | --- | --- |
| `Mod+Space` | own binds.kdl | launcher | Launcher | `panel-toggle launcher` |
| `Mod+G` | own binds.kdl | dashboard | QuickCenter | `panel-toggle control-center` |
| `Mod+Shift+Q` | own binds.kdl | session | PowerMenu | `panel-toggle session` |
| `Mod+Shift+N` | own binds.kdl | nexus | Settings | `settings-toggle` |
| `Mod+Alt+L` | own binds.kdl | lock | — | `session lock` |

Exo is the gap in that last row: it themes hyprlock, a Hyprland component, so
it has no lock of its own under niri.

`Mod+A` is Exo's upstream default for QuickCenter and is **not** used here —
`flakes/niri/config/binds` already binds it. Exo's upstream `Mod+D` launcher
and `Mod+I` settings are likewise passed over in favour of the shared keys.

## Noctalia is the easy case

It is worth contrasting with Exo. Noctalia ships `nix/home-module.nix`,
`nix/nixos-module.nix` and `nix/package.nix`, is actively maintained, and needs
no seeding, no config-directory workaround and no runtime dependency wrangling:
the module is the enum value, `programs.noctalia.enable`, a unit retarget and
the binds.

The one wrinkle is how it binds its service. Upstream uses
`config.wayland.systemd.target` for `PartOf`/`After`/`WantedBy`, which is a
single home-manager option shared by *every* wayland user service. Pointing
that at `desktop-shell.target` would drag unrelated services along with it, so
the module overrides the three fields on `systemd.user.services.noctalia`
instead — the same shape `flakes/dms/hm.nix` uses.

`noctalia msg <command>` is the IPC entry point, and `noctalia-dev/noctalia-greeter`
exists if the dank-greeter is ever swapped out.
