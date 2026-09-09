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

## `preferences` exists because some Vivaldi prefs have no UI

Vivaldi 8.3 added `vivaldi.tabs.show_pinned_group` (VB-94794, "Align pinned
tabs horizontally when tab bar is on the left or right"), default **true**, and
shipped no settings toggle for it — the key appears in `prefs_definitions.json`
and is read browser-side; `bundle.js` never names it. With it on, pinned tabs
render into a `span.pinned-group` that is a *sibling* of `.tab-strip`, so
Awesome-Vivaldi's `FavouriteTabs.css` — whose every selector is
`#tabs-container .tab-strip > span:has(.is-pinned):nth-child(-n + 9)` — matches
nothing and the 3×3 pinned grid collapses into one stacked column. Turning the
pref off puts pinned tabs back inside `.tab-strip` and the mod works unchanged;
no CSS override was needed.

We went the other way: `FavouriteTabs.css` is out of `cssMods` and the native
layout does the job, because the two implement the same feature and only the
mod's version breaks whenever upstream moves the tab DOM. `preferences` stays as
the mechanism — no caller sets it today.

That is also why it is a merge into the live
`Default/Preferences` rather than a generated file: Vivaldi owns that file and
rewrites it wholesale on exit, so home-manager cannot symlink it. The activation
snippet therefore skips entirely while Vivaldi is running — a merge landing
under a live browser is discarded on its next exit, and silently reverting is
worse than not running.
