# CONTEXT

The KDE/Plasma desktop module. This file covers how `home.nix` maps the niri
keybinds onto KWin.

## KWin equivalents of the niri binds

`shortcuts.kwin` is a translation of the niri binds, not an independent scheme.
niri's scrollable "columns" map to KWin window focus; niri workspaces map to KDE
virtual desktops (hence `kwin.virtualDesktops.number = 10`, matching Meta+1..0),
and the launcher hotkeys are built from the shared
`config.modules.functionality.defaults` so both compositors launch the same apps.

Deliberately not translated: the which-key menus (Mod+W/Z/A, screenshot/record)
have no KWin equivalent, and Mod+T's floating toggle has no stable action name.
They are dropped, not forgotten.
