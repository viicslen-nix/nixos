# CONTEXT

How `modules.programs.webapps` turns a URL into a chromeless chromium window,
and where the userscripts actually live.

## Violentmonkey comes from the NixOS layer

Violentmonkey is force-installed at the NixOS layer via
`programs.chromium.extensions` (`ExtensionInstallForcelist`) in the host config;
nixpkgs chromium reads that policy from `/etc/chromium/policies/managed`.

## The launchers

`webapp-<name>` is a chromeless `--app` window. `--class` sets the Wayland
`app_id` so niri can float it. It uses the default chromium profile so the
force-installed Violentmonkey is present.

Userscripts are added inside Violentmonkey (paste from
`~/.config/webapps/<name>.user.js`) — a userscript manager stores scripts in its
own DB, so there is no zero-click seed. `webapp-manage` is a normal chromium
window (toolbar) on the same profile, to manage Violentmonkey and install
userscripts; `--app` windows have no UI for that.
