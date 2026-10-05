# CONTEXT

The `desktop` preset — all graphical/physical-machine config. This file holds
the reasoning behind `default.nix`.

## Physical-machine defaults live here, not in `base`

`base` also serves WSL, which has no bootloader, no audio and no radio. So the
grub-on-EFI loader block (ESP at `/boot/efi`, `nodev`, `efiSupport`, 10
generations) sits here with `mkDefault` on every leaf — hosts differ only in
`canTouchEfiVariables`, `configurationLimit`, `timeout` and
`efiInstallAsRemovable`, and keep just those lines. `core.sound` and
`hardware.bluetooth` are imported here for the same reason; the bluetooth
module is enabled by import (`mkEnabledOption`), so a host with a hand-rolled
`hardware.bluetooth` block keeps only the settings the module lacks.

`programs.dms-greeter.configHome` is derived from the first name in `users`
(the same source `onePassword.users` reads) rather than a literal home path.
`onePassword.allowedCustomBrowsers` stays here: it is a NixOS-level option
(writes `/etc/1password/custom_allowed_browsers`), so the user file cannot set
it, and its default is empty, which would break the Vivaldi/Zen extension.

## The nixpkgs-wayland overlay is desktop-scoped

`inputs.nixpkgs-wayland.overlay` supplies bleeding-edge Wayland packages
(waybar, swww, portals, utils, …). It is added here rather than in `base` so it
only reaches graphical desktop hosts: headless/WSL hosts don't need it and
would otherwise recompile the overlaid closure from source on every update.

## Binary caches for that overlay

The caches that let the overlay and the ghostty flake substitute instead of
building from source are declared in `caches.nix` at the repo root with
`scope = "desktop"`. That scope is what keeps them off headless/WSL hosts, so a
cache is added there and never inline here.

## Graphical sudo goes through askpass, not polkit

A `sudo` with no terminal (an AI agent's shell tool, a launcher) now shows an
`lxqt-openssh-askpass` dialog instead of failing with "a terminal is required".
sudo does this on its own when stdin has no tty, `$DISPLAY` is set, and
`/etc/sudo.conf` names an askpass program. nixpkgs' sudo reads `/etc/sudo.conf`,
but NixOS writes no such file, so the preset provides it. It is copied (`mode`)
rather than symlinked into the store, because sudo ignores a `sudo.conf` it
does not consider root-owned and secure.

polkit (`pkexec`, `run0`) looked like the cleaner route, because DMS already
runs an authentication agent. It cannot work for the main caller here. opencode
runs as `opencode serve --service` under `systemd --user`, whose logind session
is the user manager's (class `manager`), not the graphical `tty1` session. A
polkit agent only answers for the session it registered in, so a `pkexec` from
the agent's shell finds no agent and fails. askpass has no notion of sessions:
all it needs is a display.

`sudo -n` still never prompts. That is the right behaviour, so a caller has to
drop `-n` to get the dialog.
