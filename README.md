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

### 📦 Adding New Programs

1. Create a module in appropriate directory (`modules/nixos/programs/` or `modules/home-manager/programs/`)
2. Import the module in the relevant `all.nix` file
3. Enable in host or user configurations

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
