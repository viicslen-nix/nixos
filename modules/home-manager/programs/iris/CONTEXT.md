# CONTEXT

Why `modules.programs.iris` is shaped the way it is — the keybinding split with
atuin and carapace, and the settings that are pinned rather than left to
upstream.

## The hook has to be a store path

Nushell has no `eval`, and `source` needs a path known at parse time, so the
hook cannot be piped in the way the posix shells do it. It is generated once at
build time (`iris init nu > $out`) and the store path is sourced.

`mkAfter` on `programs.nushell.extraConfig`: the hook reads `$env.config.hooks`,
so it has to run after the integrations that populate them (direnv, atuin)
rather than before.

## Who gets which key

IRIS is a PTY wrapper holding the terminal in raw mode, so it sees every
keystroke *before* nushell does. Whatever it binds is taken outright from
reedline, and therefore from atuin and carapace, which are only reedline
keybindings and a reedline completer. There is no sharing a key; the only
question is who gets it.

iris is the thing you touch on every keystroke, so it keeps its stock bindings
— tab, shift+tab, up, down, right, ctrl+r. atuin gives up ctrl+r
(`--disable-ctrl-r`) and keeps the up arrow, which still reaches it: iris
declines navigation on an empty prompt and passes the key through. The split
ends up clean:

    empty prompt + up   -> atuin search
    menu open + up/down -> iris moves the selection
    ctrl+r              -> iris spec/history mode toggle
    tab                 -> iris accepts (carapace loses its menu)

The bindings are spelled out in `defaultSettings` rather than left implicit, so
a future upstream default change cannot silently move them.

Tab costs carapace its completion menu — carapace still answers nushell's
completer for anything iris does not intercept, but the menu no longer opens on
Tab. To hand Tab back and run iris as a passive overlay, set
`settings.keybindings.select = "none"` and accept with the right arrow instead.

## Pinned settings

- `core.mode = "spec"`, not `"last"`. `"last"` restores the previous mode from
  `~/.local/share/iris/state.toml`, and landing in history mode makes every
  up/down overwrite the command line instead of moving a selection — correct
  for history mode, baffling as a default you did not ask for. ctrl+r still
  toggles within a session.
- `core.atuin-history = 1` reads atuin's `history.db` instead of nushell's
  `history.txt`. iris' default path is `$XDG_DATA_HOME/atuin/history.db`, which
  is where the atuin module already puts it, so no `atuin-db-path` is needed.
- `updater.check-on-startup = false` / `auto-update = 0`: Nix owns the binary,
  the self-updater would try to overwrite the store path, and `iris update`
  shells out to `curl … | sh`.
