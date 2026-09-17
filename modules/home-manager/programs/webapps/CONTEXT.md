# CONTEXT

How `modules.programs.webapps` turns a URL into a chromeless chromium window,
and where the userscripts actually live.

## Violentmonkey comes from the NixOS layer

Violentmonkey is force-installed at the NixOS layer via
`programs.chromium.extensions` (`ExtensionInstallForcelist`) in the host config;
nixpkgs chromium reads that policy from `/etc/chromium/policies/managed`.

## Other modules append entries

`apps` defaults to `[]`; WhatsApp is a *definition* inside this module's own
config block, so another module's `modules.programs.webapps.apps = [ … ]`
merges with it instead of replacing it (a host setting the option would have
silently dropped WhatsApp otherwise). `t3code` appends its own entry that way
— see `../t3code/CONTEXT.md` for why the Electron app is not used. That entry
is `floating = false` — an IDE, not a chat popup — which is why the niri and
Hyprland float rules are built from the floating entries instead of matching
`^webapp-`.

## The launchers

`webapp-<name>` is a chromeless `--app` window. `--class` sets the Wayland
`app_id` so niri can float it. It uses the default chromium profile so the
force-installed Violentmonkey is present.

Userscripts are added inside Violentmonkey (paste from
`~/.config/webapps/<name>.user.js`) — a userscript manager stores scripts in its
own DB, so there is no zero-click seed. `webapp-manage` is a normal chromium
window (toolbar) on the same profile, to manage Violentmonkey and install
userscripts; `--app` windows have no UI for that.
