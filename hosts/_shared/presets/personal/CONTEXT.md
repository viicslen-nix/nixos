# CONTEXT

The `personal` preset. This file holds the reasoning behind `home.nix`; the AI
config below it has its own [CONTEXT.md](./ai/CONTEXT.md).

## Desktop gating in `default.nix`

qmk, homarr and localsend all default to enabled by their modules, so the
preset sets them to `modules.presets.desktop.enable` explicitly; emacs and the
personal GUI apps (discord, ferdium, the git GUIs) sit in the gated list for the
same reason. A headless host with `personal` gets the CLI set only.

`adbusers` is granted here, not in `base`: android-tools is a personal package,
and a server has no reason to carry the group.

## hunk keybindings

hunk's defaults are already vim-ish (`j`/`k`, `g`/`G`, `d`/`u`, `[`/`]`); the
`keybindings` block only fills the gaps. Binding a key takes it from whatever
held it as a default, so `toggleLineNumbers` needs a new home (`ctrl+l`) once
`l` scrolls the code pane right.

## t3code package

`modules.programs.t3code.package` is `pkgs.inputs.llm-agents.t3code`, not
`llm-agents.t3code-desktop`. The latter is a `symlinkJoin` of the *stock*
`t3code.desktop`, so it never sees the module's T3 Connect patch. The module
installs the desktop output of this same package instead.
