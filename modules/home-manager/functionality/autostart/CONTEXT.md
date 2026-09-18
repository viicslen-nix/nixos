# autostart

`home.autostart` produces systemd user services (`autostart-<pname>`) bound to
`graphical-session.target`, not XDG autostart desktop entries.

It used to write `~/.config/autostart/*.desktop`. Nothing consumes those under
niri or Hyprland (no `dex`, no xdg-autostart runner), so entries silently never
launched there, while Plasma honoured them. `graphical-session.target` is
started by every compositor and DE in use (niri, Hyprland, Plasma), so one
mechanism covers all of them.

1Password was the motivating case: the one-password module wrote its own
desktop file and the user file added a second entry, so Plasma launched it
twice and niri not at all. The module now feeds `home.autostart` and nothing
else declares it. `delay` becomes `ExecStartPre=sleep`; keep it for tray apps
that need the shell's StatusNotifierWatcher up first.
