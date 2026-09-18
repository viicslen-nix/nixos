# thunderbird

The module drives home-manager's `programs.thunderbird` but ships Betterbird
(`pkgs.local.betterbird`) by default, because plain Thunderbird has no system
tray on Linux and the goal is an email client that keeps running, and
notifying, after its window is closed.

- Betterbird was dropped from nixpkgs in late 2024, so `flakes/packages` wraps
  the upstream Linux tarball on top of `thunderbird-esr-bin-unwrapped` and
  `wrapThunderbird`. No forge behind it: `just bump betterbird --version <x>`.
- It uses the same `~/.thunderbird` profile directory as Thunderbird
  (`application.ini` has `Profile=thunderbird`), so HM's `profiles.ini`,
  `user.js` and the persisted `.thunderbird` directory carry over unchanged.
- `mail.closeToTray` only works on desktops listed in
  `mail.minimizeToTray.supportedDesktops`, matched against
  `XDG_CURRENT_DESKTOP`. Upstream's list has hyprland but not niri, hence the
  override that appends it.
