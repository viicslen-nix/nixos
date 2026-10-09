# CONTEXT

The `dev` preset: general coding tools, on every host that writes code. It
holds what is not tied to an employer, so `work` keeps only employer access and
`personal` only your own apps. A personal-only dev box is `base` + `dev` +
`personal`.

## What lives here

- `default.nix`: what needs the system. The container engines and the local
  service stack (Traefik, MySQL, Redis, …), corepack, the mkcert program, the
  `*.local` loopback names, the ports those services open, and
  `permittedInsecurePackages` (`useGlobalPkgs` ignores the home-manager one).
  vitess is not here: only `dostov-dev` imports it.
- `home.nix`: everything else, as `home.packages` grouped under comment
  headers, plus the AI harnesses (`programs.claude-code`, codex, copilot,
  antigravity, pi, opencode v1 as the default), zed, t3code, hunk, k9s/krr, the
  kubectl and sail aliases and the intelephense licence.

A package a module already installs is not listed here too: `vscode-fhs` is
`users/neoscode`'s `defaults.editor`, `gh` is `programs.gh`, `hunk` is
`programs.hunk`, `antigravity-cli` is `programs.antigravity-cli`, `meld` is the
jujutsu module's.
`just inventory --dupes` shows any that creep back.

## `home.packages` is not `systemPackages`

The system profile is built with `ignoreCollisions`, so two packages shipping
the same file never failed: one silently won. home-manager's `home.path` is a
plain `buildEnv`, and the same pair fails the build there. Moving a package from
`systemPackages` to `home.packages` therefore needs a collision check, not just
an eval. That is why only `gcc13` is listed: base's default `gcc` and work's
`gcc13` both ship `bin/gcc`, and gcc 13 was the one that won in the system
profile.

## hunk keybindings

hunk's defaults are already vim-ish (`j`/`k`, `g`/`G`, `d`/`u`, `[`/`]`); the
`keybindings` block only fills the gaps (vim's `ctrl+` page/half-page scrolls,
listed alongside the defaults they would otherwise replace). Binding a key takes
it from whatever held it as a default, so `toggleLineNumbers` needs a new home
(`ctrl+l`) once `l` scrolls the code pane right.

## t3code

The module comes from the `ai` subflake (`homeManagerModules.t3code`). Its
package is overridden to `t3code.nightly` from `flakes/packages`, which is both
the served instance and the desktop app.
