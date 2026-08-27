# Personal NixOS Configuration

> **Note**: This is my personal NixOS configuration. It's tailored to my specific needs, hardware, and preferences. While you're welcome to browse and learn from it, please be aware that applying these configurations directly to your system may not work as expected or could potentially cause issues.

## 📖 Overview

This repository contains my complete NixOS configuration using Nix Flakes, featuring a modular architecture with support for multiple hosts, desktop environments, and development workflows.

## 🏗️ Architecture

The configuration is built using a modular flake-based architecture with the following key components:

- **Flake-based**: Modern Nix configuration using flakes for reproducible builds
- **Multi-host support**: Configurations for different machines and environments
- **Modular design**: Reusable modules for NixOS and Home Manager
- **Development environments**: Multiple dev shells for different workflows
- **Secrets management**: Age-encrypted secrets handling

## 💻 Supported Hosts

Hosts and the presets each one receives are declared in `hosts/default.nix`.

### 🖥️ Physical Machines

- **asus-zephyrus-gu603**: ASUS Zephyrus GU603 gaming laptop with NVIDIA graphics (niri)
- **dostov-dev**: Intel development workstation (niri)
- **home-desktop**: Desktop workstation, CachyOS kernel (niri)
- **lenovo-legion-go**: Lenovo Legion Go handheld, KDE Plasma 6 on Jovian-NixOS

### 🌐 Virtual Environments

- **wsl**: Windows Subsystem for Linux setup

## 🎨 Desktop Environments

- **niri**: primary Wayland compositor on the desktop/laptop hosts
- **DankMaterialShell (DMS)**: shell, panel, and login greeter for niri
- **KDE Plasma 6**: used on the Legion Go handheld
- **Hyprland**: available as a module (`flakes/hyprland`), not currently enabled by default

## 🛠️ Development Environments

Pre-configured development shells (see `dev-shells/`):

- **Kubernetes**: Container orchestration development
- **Laravel/PHP**: Web development with PHP and Laravel
- **Python**: Python development with common tools

## 📦 Key Features

### 🔧 System Management

- **Impermanence**: Stateless system with persistent data management
- **Disko**: Declarative disk partitioning
- **Secrets**: Age-encrypted secrets management
- **Backups**: Automated backup solutions with Restic

### 🖥️ Desktop Experience

- **niri**: Scrollable-tiling Wayland compositor
- **DankMaterialShell**: Status bar, panels, and login greeter
- **Stylix**: System-wide theming
- **Multiple browsers**: Firefox, Chromium, Zen Browser, Vivaldi support

### 🛠️ Development Tools

- **Neovim**: Heavily customized with nvf
- **Terminal multiplexers**: tmux, Zellij support
- **Shells**: Nushell, Zsh configurations
- **Version control**: Git, Jujutsu (jj)
- **Containers**: Docker, Podman support

### 📱 Applications

- **Gaming**: Steam integration
- **Productivity**: Various development and productivity tools
- **Multimedia**: Audio/video editing capabilities
- **Networking**: VPN (Mullvad), network tools

## 🚀 Quick Start

### 📋 Prerequisites

- NixOS installed system
- Git
- Basic understanding of Nix/NixOS

### 🔧 Installation

1. **Clone the repository**:

   ```bash
   git clone <repository-url> /etc/nixos
   cd /etc/nixos
   ```

2. **Review and customize**:
   - Check `hosts/` for available configurations
   - Modify hardware configurations to match your system
   - Update user configurations in `users/`

3. **Install using the script**:

   ```bash
   chmod +x install.sh
   ./install.sh
   ```

   Or manually:

   ```bash
   sudo nixos-rebuild switch --flake .#<hostname>
   ```

### ⚡ Available Commands (using Just)

```bash
# Update all subflakes and root flake inputs
just update

# Update only root inputs, or a single input / subflake
just update-main
just update-input nixpkgs
just update-subflake niri

# List the local packages in flakes/packages
just packages

# Check local packages against their latest upstream version
just outdated

# Bump version + hash of a local package in flakes/packages (nix-update)
just bump app-images.t3code
just bump coderabbit --version 0.4.5   # upstream nix-update can't autodetect
just bump-all                          # sweep every local package
just bump-outdated                     # bump only what `just outdated` flags

# Rebuild and switch (nh wrapper); use boot/test in place of switch as needed
just upgrade switch

# Or rebuild directly with nixos-rebuild
just rebuild switch

# Update flake inputs, then rebuild (full upgrade)
just full-upgrade

# Run the eval tests
just test

# View all available commands
just --list
```

> Heavy rebuilds are resource-intensive; you can pass build limits through, e.g.
> `just upgrade boot --cores 3 --max-jobs 2`.

## 🔧 Customization

### 🏠 Adding a New Host

1. Create a new directory in `hosts/`
2. Add configuration files (`default.nix`, `hardware.nix`, etc.)
3. Update `hosts/default.nix` to include the new host
4. Rebuild with `just upgrade switch`

### 📦 Adding New Modules

1. Create a `default.nix` under the appropriate `modules/nixos/` or `modules/home-manager/` category
2. Register it under `flake.modules.nixos` or `flake.modules.homeManager`
3. Import it from the generated `nixosModules` or `homeModules` tree

### 📦 Overriding a packaged app with a fork

`overlays/default.nix` → `superset-fork` replaces
`pkgs.inputs.packages.superset.desktop` with the build from
[`viicslen/superset-desktop`](https://github.com/viicslen/superset-desktop)
(private; thread-style sidebar). Nothing at the use site changes — the `work`
preset still installs `pkgs.inputs.packages.superset.desktop` — so reverting is
deleting the overlay from the list in `base`.

Three things make it work:

- It is listed **after** `flake-inputs` in `base`, which is the overlay that
  creates `pkgs.inputs` at all.
- It takes the fork's `superset-desktop` attr, not `superset`: the Superset CLI
  already installs `bin/superset`, and both land in the same profile.
- The private input resolves through `access-tokens` (above). **A rebuild now
  needs that token** — without it, evaluation fails at the flake input, not at
  the package.

### 🎮 Gaming

Import `nixosModules.functionality.gaming` for the safe desktop gaming stack: Steam,
GE-Proton, Protontricks, GameMode, Gamescope, Decky Loader, ZRAM, Wine, controller
rules, launchers, and overlay tools. The dedicated Gamescope login session uses its
own Holo/Gamescope portal routing without changing desktop portal preferences.
Decky Loader's required root service is enabled by default. Other hardware-specific
or privileged features remain opt-in under `modules.functionality.gaming`, including
Gamescope capabilities/WSI, controller drivers, Steam firewall ports, low-latency
PipeWire, and SteamOS platform sysctls.

### 🐚 Development Shells

Access development environments:

```bash
nix develop .#kubernetes  # Kubernetes development
nix develop .#laravel     # Laravel development
nix develop .#python      # Python development
```

## 🔐 Secrets Management

This configuration uses `agenix` for secrets management:

- Secrets are stored in `secrets/` directory
- Encrypted with age
- Referenced in `secrets/default.nix`

Every secret is encrypted to **one portable key**, `~/.ssh/agenix`, rather than
to per-host SSH host keys. Bringing up a new host therefore needs no
re-encryption round trip — copy that key in and every secret decrypts.
`base` sets `age.identityPaths` accordingly.

### GitHub token for private flakes

`secrets/github/nix-token.age` holds one PAT — just the token, no trailing
newline, no surrounding syntax — and `base` wires it, so private repos work on
any host with no hand-written `~/.config/nix/nix.conf`. Nix wants that token on
two paths that never see each other:

| Consumer | Covers | File |
| --- | --- | --- |
| `nix-daemon`'s `EnvironmentFile` | `pkgs.fetchurl` inside a **fixed-output derivation**, e.g. a private release asset | `/run/nix-daemon-env`, `GITHUB_TOKEN=…`, `root:root 0400` |
| `access-tokens` in `/etc/nix/nix.conf` | flake **inputs** — `nix run github:owner/private-repo` | `/run/nix-access-tokens`, nix.conf syntax, `root:users 0440`, `!include`d |

`fetchurl` reads `impureEnvVars` from the **daemon's** environment, not yours —
exporting the token before `nix run` does nothing. Flake inputs are the mirror
image: fetched by the *client*, which never sees the daemon's environment. One
setting cannot serve both, hence two files.

`system.activationScripts.nixTokenFiles` shapes both from the one secret. They
cannot be `writeText`ed instead: `/nix/store` is world-readable (`drwxrwxr-t`)
and store paths are substitutable, so a token baked into a derivation would leak
to every local user and to any cache the closure reaches — the whole reason
agenix exists. Only the *script* is declarative; the token joins it at
activation, into tmpfs, so neither file persists.

`/run/nix-access-tokens` is group-readable because a root-only file would break
`nix run` for the user who needs it. Any local user in `users` can read the
token — the same exposure as the plaintext `~/.config/nix/nix.conf` it replaces.

Rotate:

```bash
gh auth token | tr -d '\n' \
  | age -r "$(grep -o 'ssh-ed25519 [^"]*' secrets/default.nix | head -1)" \
        -o secrets/github/nix-token.age
```

## ⚙️ Hardware Support

### 🎮 Graphics

- **NVIDIA**: Proprietary drivers with proper configuration
- **Intel**: Integrated graphics support

### 💻 Laptops

- **ASUS**: Specific optimizations for ASUS hardware
- **Power management**: TLP, auto-cpufreq
- **Display**: HiDPI and multi-monitor support

### 🔌 Peripherals

- **Bluetooth**: Full Bluetooth stack
- **Audio**: PipeWire audio system
- **Keyboards**: QMK and custom layouts support

## 📋 Dependencies

This configuration pulls from numerous upstream sources:

- **NixOS/nixpkgs**: Core packages
- **Home Manager**: User environment management
- **Hyprland**: Wayland compositor
- **Stylix**: System theming
- **nvf**: Neovim configuration framework
- **And many more** - see `flake.nix` for complete list

## ⚠️ Important Notes

- **Personal Configuration**: This is specifically tailored for my use case
- **Hardware Specific**: Some configurations are tied to specific hardware
- **Experimental Features**: Uses unstable Nix features and packages
- **Regular Updates**: Configurations change frequently
- **No Warranty**: Use at your own risk

## 🤝 Contributing

While this is a personal configuration, if you find bugs or have suggestions:

1. Open an issue describing the problem
2. Provide relevant system information
3. Include error messages or logs

## 📜 License

This configuration is provided as-is for educational and reference purposes. Feel free to learn from it, but please adapt it to your own needs rather than using it directly.

## 🙏 Acknowledgments

This configuration is built upon the excellent work of the Nix community and draws inspiration from many other configurations. Special thanks to:

- The NixOS team and community
- Home Manager maintainers
- Hyprland developers
- All the package maintainers and contributors

---

*Remember: This is a personal configuration. Always review and understand what you're applying to your system before running any commands.*
