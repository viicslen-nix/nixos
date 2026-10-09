<div align="center">

# ❄️ viicslen's NixOS

**One flake, five machines, everything declarative.**

[![NixOS unstable](https://img.shields.io/badge/NixOS-unstable-5277C3?style=flat-square&logo=nixos&logoColor=white)](https://nixos.org)
[![flake-parts](https://img.shields.io/badge/built_with-flake--parts-7EBAE4?style=flat-square&logo=nixos&logoColor=white)](https://flake.parts)
[![Home Manager](https://img.shields.io/badge/Home_Manager-integrated-41439A?style=flat-square)](https://github.com/nix-community/home-manager)
[![niri](https://img.shields.io/badge/WM-niri-E0A458?style=flat-square)](https://github.com/YaLTeR/niri)
[![Stylix](https://img.shields.io/badge/theme-material--darker-212121?style=flat-square)](https://github.com/nix-community/stylix)
[![Checks](https://img.shields.io/github/actions/workflow/status/viicslen-nix/nixos/checks.yml?style=flat-square&label=checks)](https://github.com/viicslen-nix/nixos/actions/workflows/checks.yml)

</div>

> [!NOTE]
> This is a personal configuration, shaped around my hardware and habits.
> Browse it, borrow from it, but don't apply it as-is.

## Contents

- [At a glance](#at-a-glance)
- [Hosts](#hosts)
- [Layout](#layout)
- [Presets](#presets)
- [Subflakes](#subflakes)
- [Desktop](#desktop)
- [Usage](#usage)
- [Secrets](#secrets)
- [Extending](#extending)

## At a glance

| | |
| --- | --- |
| **Base** | `nixos-unstable`, with `pkgs.stable` (26.05) and `pkgs.unstable` overlays |
| **Structure** | [flake-parts](https://flake.parts); every file in `parts/` is auto-imported |
| **Composition** | Hosts pick presets (`base`, `desktop`, `work`, `personal`) and import modules by path |
| **Modules** | ~50 NixOS and ~40 Home Manager modules, discovered automatically |
| **Inputs** | 19 dependencies resolved lazily through [omniflake](https://github.com/fzakaria/omniflake) |
| **Desktop** | niri + DankMaterialShell, themed system-wide by Stylix |
| **Secrets** | agenix, every secret encrypted to one portable key |
| **Disks** | disko layouts, btrfs on LVM |
| **CI** | Formatting, secret scanning, and evaluation of the niri hosts |

## Hosts

Declared in [`hosts/default.nix`](hosts/default.nix), all `x86_64-linux`.

| Host | Machine | Session | Presets |
| --- | --- | --- | --- |
| `dostov-dev` | Intel + NVIDIA workstation, rotated dual monitors | niri, Hyprland | base · desktop · work · personal |
| `home-desktop` | Intel + NVIDIA desktop, CachyOS kernel | niri, Hyprland | base · desktop · work · personal |
| `asus-zephyrus-gu603` | ASUS Zephyrus G16 laptop, NVIDIA PRIME | niri | base · desktop · work · personal |
| `lenovo-legion-go` | Lenovo Legion Go handheld on [Jovian](https://github.com/Jovian-Experiments/Jovian-NixOS), CachyOS kernel | Steam / Plasma 6 | base · desktop |
| `wsl` | [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) with Docker Desktop | headless | base · work · personal |

## Layout

```text
.
├── flake.nix        # inputs and the omniflake mapping, nothing else
├── parts/           # flake-parts modules, one concern per file
├── hosts/           # one directory per machine + the host table
├── presets/         # base · desktop · work · personal · linode
├── modules/
│   ├── nixos/           # containers, core, desktop, hardware, programs, services, …
│   └── home-manager/    # programs and functionality, per user
├── users/           # Home Manager entry point per user
├── disko/           # reusable disk layouts
├── overlays/        # pkgs.stable, pkgs.unstable, pkgs.local, pkgs.inputs, tweaks
├── shells/          # nix develop environments
├── secrets/         # agenix-encrypted secrets
├── docs/inventory/  # generated: what each host installs, per source file
├── caches.nix       # every binary cache, declared once
└── flakes/          # subflakes, each its own repo (git submodules)
```

A module is any `default.nix` under `modules/`. It appears in the
`nixosModules` / `homeModules` trees that hosts and presets receive, namespaced
like its directory:

```nix
{nixosModules, ...}: {
  imports = with nixosModules; [hardware.nvidia programs.docker functionality.gaming];
}
```

## Presets

| Preset | What it brings |
| --- | --- |
| **base** | Every host, server-safe. Home Manager, agenix, NUR, nh, zsh, CLI tooling, binary caches, the flake registry |
| **desktop** | Everything graphical: niri, Hyprland, DMS and its greeter, Stylix, fonts, sound, Bluetooth, printing, Plymouth, 1Password |
| **work** | Development stack: Docker/Podman, local containers (Traefik, MySQL, Redis, Meilisearch, Qdrant, …), mkcert CA, PHP, Node, Go, cloud and Kubernetes CLIs, AI harnesses |
| **personal** | QMK, Emacs, Discord, Obsidian, LocalSend, the Neovim build, the personal AI profile |
| **linode** | Linode networking and support tools (no host uses it today) |

GUI-only packages in `work` and `personal` are gated on the desktop preset, so
headless hosts such as `wsl` stay lean.

What each preset actually ends up installing on each host is generated, not
hand-kept: see [`docs/inventory`](docs/inventory) (`just inventory --all --save`).

## Subflakes

Under `flakes/`, each a submodule backed by its own `viicslen-nix/*` repo.

| Subflake | Provides |
| --- | --- |
| [`lib`](flakes/lib) | Helper library: option helpers, module discovery, omniflake wiring, skill and container helpers |
| [`packages`](flakes/packages) | Local packages (Superset, Vivaldi builds, PHP, AppImages, scripts, …) with bump tooling |
| [`ai`](flakes/ai) | Portable AI-harness config for Claude Code, opencode, Codex, Copilot CLI and Antigravity: skills, MCP servers, integrations |
| [`niri`](flakes/niri) | niri-unstable, keybinds, window rules, scratchpads, which-key menus |
| [`hyprland`](flakes/hyprland) | Hyprland via UWSM, Lua config, hyprsplit, DMS integration |
| [`dms`](flakes/dms) | DankMaterialShell and its greeter |
| [`nixvim`](flakes/nixvim) | Standalone Neovim: LSPs, Telescope, Avante, Laravel tooling |
| [`emacs`](flakes/emacs) | Emacs from emacs-overlay, mirroring the Neovim setup |
| [`zed`](flakes/zed) | Zed from upstream with Nix-managed extensions |

## Desktop

| | |
| --- | --- |
| **Compositor** | [niri](https://github.com/YaLTeR/niri), with Hyprland as a second session on the desktops |
| **Shell & greeter** | [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell); Caelestia, Exo and Noctalia are one option away (`modules.desktop.shell`) |
| **Theme** | Stylix, base16 `material-darker`, Kora icons, Bibata cursor |
| **Fonts** | FiraCode Nerd Font Mono, Victor Mono, Noto |
| **Terminal** | Ghostty |
| **Browser** | Vivaldi (snapshot), Zen |
| **Editor** | Neovim (nixvim), Zed, VS Code |
| **Shell** | zsh + starship, atuin, zoxide; tmux with worktrunk-managed worktree sessions |

Gaming lives in `nixosModules.functionality.gaming`: Steam, GE-Proton,
GameMode, Gamescope (with its own login session), Decky Loader and controller
rules. Privileged extras stay opt-in under `modules.functionality.gaming`.

## Usage

Recipes live in the [`Justfile`](Justfile); `just --list` shows them all.

```bash
just upgrade              # rebuild and switch via nh (boot / test also work)
just update               # bump every subflake, then the root inputs
just full-upgrade         # update, then rebuild for next boot
just build home-desktop   # build one host without switching
just build-all            # nix flake check: every host + all checks
just inventory            # what this host installs/enables, and which file put it there
```

<details>
<summary><b>All recipes</b></summary>

| Area | Recipe | Does |
| --- | --- | --- |
| Deploy | `upgrade [cmd]` | Rebuild through `nh os` |
| | `rebuild [cmd]` / `rebuild-path [cmd]` | Plain `nixos-rebuild`, the latter for dirty trees |
| | `commit-and-upgrade MSG [cmd]` | Commit, then rebuild |
| Update | `update` / `update-main` | Everything / root inputs only |
| | `update-input X` / `update-subflake X` | One input / one subflake (re-locked in the root) |
| | `omniflake-search TERM` | Find a flake in the omniflake index |
| | `sync-caches` | Regenerate the flake's `nixConfig` from `caches.nix` |
| Packages | `packages` / `outdated` | List local packages / compare with upstream |
| | `bump ATTR` / `bump-outdated` / `bump-all` | Update versions and hashes with nix-update |
| Skills | `skills` / `vendor-skills REPO` / `update-skills` | Manage vendored AI skills |
| Dev | `fmt` / `lint` / `check-file F` / `repl` | treefmt (fixes), deadnix + statix (report), parse check, REPL |
| | `inventory [HOST\|--all]` | Packages, modules, programs, services, containers and units per host, each with its source file; `--markdown`, `--json`, `--save` (writes [`docs/inventory`](docs/inventory)), `--dupes` (packages defined in more than one place) |
| Servers | `tmux-push HOST [NAME]` | Install the portable tmux config on a non-NixOS server over ssh |
| Maintenance | `gc` / `optimize` / `clean` / `history` | Store and generation housekeeping |
| Git | `commit MSG` / `push MSG` | Commit, or commit and push |

</details>

> [!TIP]
> Big rebuilds are memory-hungry. Pass limits straight through:
> `just upgrade boot --cores 3 --max-jobs 2`.

### Development shells

```bash
nix develop .#laravel      # PHP + xdebug, Composer, Node 22, Bun, DDEV, Stripe CLI
nix develop .#kubernetes   # kubectl, Helm + helm-secrets, k9s, stern, minikube
nix develop .#python       # Python 3
```

### Fresh install

From the NixOS live installer, in a clone of this repo (with submodules):

```bash
./install.sh <host> [path/to/agenix-key]
```

It partitions with the host's disko layout, copies the repo to
`/mnt/etc/nixos`, installs the agenix key so secrets decrypt, and runs
`nixos-install`, confirming each step. Hosts without a disko layout need `/mnt`
partitioned and mounted by hand first.

## Secrets

Managed with [agenix](https://github.com/ryantm/agenix). Every secret in
`secrets/` is encrypted to **one portable key**, `~/.ssh/agenix`, rather than
to per-host SSH keys, so a new machine needs no re-encryption round trip:
copy the key in and everything decrypts.

`just secret <name>` edits one, e.g. `just secret cliproxyapi/api-key`, or takes
the new value on stdin. A new secret needs its rule in `secrets/default.nix`
first.

<details>
<summary><b>GitHub token for private flakes</b></summary>

`secrets/github/nix-token.age` holds one bare PAT (no trailing newline), and
`base` wires it so private repos work on any host without a hand-written
`nix.conf`. Nix needs it on two paths that never see each other:

| Consumer | Covers | File |
| --- | --- | --- |
| `nix-daemon`'s `EnvironmentFile` | `pkgs.fetchurl` in a fixed-output derivation, e.g. a private release asset | `/run/nix-daemon-env`, `GITHUB_TOKEN=…`, `root:root 0400` |
| `access-tokens` in `/etc/nix/nix.conf` | flake inputs, e.g. `nix run github:owner/private-repo` | `/run/nix-access-tokens`, `root:users 0440`, `!include`d |

`fetchurl` reads its impure variables from the **daemon's** environment, while
flake inputs are fetched by the **client**, so one setting cannot serve both.
`system.activationScripts.nixTokenFiles` writes both files into tmpfs at
activation. They are never `writeText`ed: `/nix/store` is world-readable and
substitutable, so a token in a derivation would leak.

`/run/nix-access-tokens` is group-readable because `nix run` needs it as your
user, the same exposure as the plaintext `~/.config/nix/nix.conf` it replaces.

Rotate:

```bash
gh auth token | tr -d '\n' \
  | age -r "$(grep -o 'ssh-ed25519 [^"]*' secrets/default.nix | head -1)" \
        -o secrets/github/nix-token.age
```

</details>

## Extending

**A host:** add `hosts/<name>/default.nix` (plus `hardware.nix`), then list it
with its `system` and `presets` in `hosts/default.nix`. A disko layout is one
import away: `(diskoLayouts.btrfs-lvm {device = "/dev/disk/by-id/…";})`.

**A module:** drop a `default.nix` under `modules/nixos/<category>/<name>/` or
`modules/home-manager/<category>/<name>/`. It is discovered automatically and
reachable as `nixosModules.<category>.<name>`. Path components starting with
`_` are skipped.

**A flake-parts concern:** drop a file into `parts/`.

**A binary cache:** add it to `caches.nix`, then run `just sync-caches`.

## Acknowledgments

Built on the work of the NixOS and Home Manager communities, and the authors of
niri, DankMaterialShell, Stylix, nixvim, Jovian-NixOS, omniflake and the many
flakes this pulls in.
