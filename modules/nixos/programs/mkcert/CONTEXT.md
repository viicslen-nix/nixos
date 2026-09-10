# CONTEXT

## One CA, committed — because there were three

Before `rootCA` was wired up this workstation had three mkcert CAs: the one
`mkcert` makes per user (`~/.local/share/mkcert`), the one
`mkcert-generate-certs.service` made for itself (`/var/lib/mkcert/ca`), and an
unused pair in `secrets/mkcert`. Traefik served certs from the second while the
browser trusted only the first, so every `*.test` container was "insecure".

The shared CA is split by what it is: `rootCA.pem` is public and sits plain in
`secrets/mkcert/` so it can be a store path, which `security.pki.certificateFiles`
needs (the bundle is built at build time — a `/run/agenix/…` path cannot be
read in the sandbox). Only the key is age-encrypted. The service copies both
under `certDir/ca` because mkcert expects cert and key side by side in `CAROOT`.

## Chromium and Electron do not read /etc/ssl

On Linux they trust the Chrome Root Store plus `~/.pki/nssdb`, so
`security.pki` alone never reaches Vivaldi or an Electron app's built-in
browser (t3code). The home-manager activation step imports the CA with
`certutil -A -t C,,`, which is what `mkcert -install` would do if `certutil`
were on PATH — it isn't by default, and mkcert then skips NSS with only a
warning. The entry is deleted and re-added so a rotated CA replaces the old one
instead of failing on the nickname.

## Users sign with the shared CA too

`CAROOT` is set session-wide to `certDir/ca`, so a plain `mkcert`, `mkcert-dev`
and `generate-cert` (base preset) all issue from the same CA the browser
trusts. That needs the key readable by users: the service installs it
`0640 root:users` — every account here has `users` as its primary group. It is
no wider than the per-user CA it replaces, whose key sat 0400 in `$HOME`.
Certs issued earlier under `~/.local/share/mkcert` are still signed by that old
CA; re-run `generate-cert` for any you still use.
