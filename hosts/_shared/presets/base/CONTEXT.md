# CONTEXT

The `base` preset — universal, server-safe config every host imports. This file
holds the reasoning behind `default.nix`; the comments there only warn.

## `modules.presets.desktop.enable` is declared here, not in `desktop`

The marker is set by the `desktop` preset so other presets (work, personal) can
gate GUI-only bits to graphical hosts. It is *declared* in `base` because `base`
is always imported, so reading it never hits an undeclared option.

## Always-on module imports

`imports` and `home-manager.sharedModules` both carry modules that look
inactive. `impermanence` (nixos and home-manager alike) is imported for the
options the persistence helpers read; it stays disabled unless a host enables
it. `defaults` and `autostart` likewise declare options other modules read.
Dropping any of them turns a read elsewhere into an undeclared-option error.

## What `base` deliberately does not carry

Anything that assumes a physical machine lives in `desktop`: sound
(`core.sound`), bluetooth, the grub-on-EFI loader defaults. `base` also has no
`adbusers` group and no `defaultUserShell` — per-user `shell` is set with
`useDefaultShell = false`, so the global default was never read, and groups a
preset needs are added by that preset.

`users.mutableUsers = false` and root's password hash are `mkDefault` here
because every host set the same two lines; a host overrides either, it does
not restate them. `nix.gc` is absent on purpose: `programs.nh.clean` owns
garbage collection.

## direnv's log filter, and why not `silent`

nix-direnv's `direnv: export +AR +AS +...` line is a single ~1.1KB string
listing every variable the dev shell touched. On a 100-column terminal it wraps
to a dozen rows, and the prompt hook reprints it on every `cd`, so `clear`
leaves the prompt stranded mid-screen. The `log_filter` keeps the short status
lines that say direnv is doing something and drops the dump.
`programs.direnv.silent = true` would suppress all of it instead — including the
useful lines — which is why the filter is used rather than the flag.

## nushell is installed explicitly

`environment.shells` advertises `/run/current-system/sw/bin/nu`, and editors
(PhpStorm, Cursor) cache that absolute path. The account shell is zsh now, so
nushell no longer arrives as a side effect of being the login shell and has to
be in `systemPackages`.

## Secrets: one portable key

Every secret is encrypted to one portable key the user carries
(`~/.ssh/agenix`), never to per-host SSH host keys. That is what keeps a new
host zero-setup: drop the key in and every secret decrypts, with no
re-encryption round trip to add the machine as a recipient.

`secrets/github/nix-token.age` holds just the PAT — no trailing newline and no
surrounding syntax. Nix needs it in two different file formats; both are shaped
from this one secret by the activation script below, so a rotation is
`gh auth token | age …` and cannot go half-applied.

## Why the token files are shaped at activation, not `writeText`ed

`/nix/store` is world-readable (`drwxrwxr-t`) and store paths are
substitutable, so a token baked into a derivation leaks to every local user and
to any cache the closure reaches. Only the *script* is declarative; the token
joins it at activation.

Two details of that script:

- It carries `deps = ["agenix"]` (agenix's empty marker script) and guards with
  `if` rather than an early `exit`. Activation snippets are concatenated into
  one script, so exiting here would skip every snippet after it.
- `shapeToken` writes then renames, creating the temp file `0400` and only then
  relaxing the mode, so no reader ever catches a partial or briefly
  over-permissive token.

The two formats exist because the two consumers read different environments:

- `/run/nix-daemon-env` (`0400 root`) — `pkgs.fetchurl` reads its
  `impureEnvVars` from the **nix-daemon's** environment, not your shell's. This
  is the only way a fixed-output derivation can authenticate to a private
  GitHub release asset.
- `/run/nix-access-tokens` (`0440 users`) — flake *inputs* are the mirror
  image: fetched by the client process, which never sees the daemon's
  environment. Group-readable, because a root-only file would break `nix run`
  for the user who needs it.

`nix.extraOptions` pulls the second in with `!include`, the tolerant form — nix
skips the file if it is not there yet (first boot, before agenix has run)
instead of refusing to start.

## Binary caches

The table lives in `caches.nix` at the repo root. Adding a cache there — not in
this preset — is what keeps the flake's own `nixConfig` and the own-nixpkgs
routing in step with it.
