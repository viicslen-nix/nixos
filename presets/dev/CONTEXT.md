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
  headers, plus zed, t3code, hunk, k9s/krr, the kubectl and sail aliases and
  the intelephense licence. The AI harnesses are the `ai` preset's, which
  `default.nix` imports.

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

## t3code

The module comes from the `ai` subflake (`homeManagerModules.t3code`). Its
package is overridden to `t3code.nightly` from `flakes/packages`, which is both
the served instance and the desktop app.

`stateDir` is set to `$XDG_DATA_HOME/t3code` instead of the module's `~/.t3`
default, to keep the dotdir out of `$HOME`. Changing it does not move anything:
the next start opens an empty home, the T3 Connect login is missing, and the
tunnel stays offline while the service still reports healthy. Moving the data
also means rewriting the absolute paths the server stores (`statev2.sqlite`:
`workspace_root`, `worktree_path` and the event/projection payload JSON), running
`git worktree repair` from each origin repo, adding `../` to the relative
`gitdir:` of every submodule inside a moved worktree, and renaming the
`~/.config/claude/projects/-home-<user>--t3-*` session dirs to the new encoded
cwd, or Claude sessions stop resuming. The move to the XDG path was done on
2026-10-30.

## Commit signing from a key file

git and jujutsu sign with plain `ssh-keygen` from
`/run/agenix/git-signing-key`, the private half of the shell profile's
`git-signing-key.pub`, exported from 1Password. It used to go through
`op-ssh-sign`, which asks the 1Password GUI to approve each signature on the
machine's own screen; over SSH, or on the headless `agents` host, nobody can,
so commits hung. GitHub sees the same key, so commits stay "Verified".

It lives here, not in the 1Password module, because headless dev hosts have no
1Password. A host without `dev` (the handheld) does not sign at all. Only
signing moved: SSH auth still goes through the 1Password agent where there is
one, so a push over SSH still waits for an approval.

The cost: anything running as the user can sign as them without asking. The
key must be OpenSSH format (`op read "…/private key?ssh-format=openssh"`), or
`ssh-keygen -Y sign` rejects it.
