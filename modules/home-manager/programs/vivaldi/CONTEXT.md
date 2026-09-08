# CONTEXT

Why `modules.programs.vivaldi` rebuilds the package instead of wrapping it, and
why the desktop entry name is derived from the channel.

## The mods live inside the package

Vivaldi's launcher resolves its own directory through `readlink -f "$0"`, and
Chromium finds `resources/` next to the real binary, so a patched copy wrapped
around the original store path is simply never read. `moddedPackage` therefore
overrides the derivation and writes into
`$out/opt/vivaldi[-snapshot]/resources/vivaldi`.

Based on <https://github.com/budlabs/vivaldi-autoinject-custom-js-ui>.

Awesome-Vivaldi's layout: the loader sits at the resources root and discovers
everything under `user_mods/` at runtime, so one script tag covers every mod
(see the modpack's `install.sh`).

## `finalPackage` is the only thing that should be launched

`finalPackage` is `package` with the mod pack baked into its resources and the
launch flags wrapped around it. Anything that *launches* Vivaldi —
`functionality.defaults.browser`, a compositor keybind — must point here and
not at `package`, or it execs the unmodded binary by absolute store path and
silently bypasses both the mods and the flags.

## `desktopFileName`

Vivaldi names its desktop entry after the *channel* — `vivaldi-snapshot` /
`vivaldi-stable` — never after the package. Anything deriving a `.desktop` name
from this package (`functionality.defaults`' mime handlers) has nothing to go on
otherwise: `runCommand` sets `name` but no `pname`, so the lookup lands on null.
The stock package does carry `pname = "vivaldi"`, but that fallback only ever
produced a `vivaldi.desktop` that does not exist — a broken association that
failed quietly instead of loudly. The build asserts the file is present so an
upstream rename fails loudly instead.
