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

## 📁 Repository Structure

```
├── flake.nix              # Main flake configuration
├── flake.lock             # Locked flake inputs
├── Justfile               # Task runner for common operations
├── secrets.nix            # Secrets configuration
├── install.sh             # Installation script
├── diff.sh                # Configuration diff utility
│
├── hosts/                 # Host-specific configurations
│   ├── asus-zephyrus-gu603/  # Gaming laptop configuration
│   ├── dostov-dev/           # Development machine
│   └── wsl/                  # WSL environment
│
├── modules/               # Reusable modules
│   ├── nixos/             # NixOS system modules
│   │   ├── desktop/       # Desktop environments (GNOME, Hyprland, KDE)
│   │   ├── hardware/      # Hardware-specific configurations
│   │   ├── programs/      # System programs
│   │   └── presets/       # Configuration presets
│   └── home-manager/      # Home Manager modules
│       ├── programs/      # User programs
│       └── functionality/ # User functionality modules
│
├── dev-shells/            # Development environments
│   ├── kubernetes.nix     # Kubernetes development
│   ├── laravel.nix        # PHP/Laravel development
│   └── python.nix         # Python development
│
├── flakes/                # Custom flakes
│   ├── astal-shells/      # Custom shell configurations
│   └── nvf/               # Neovim configuration
│
├── pkgs/                  # Custom packages
│   ├── by-name/           # Package definitions
│   ├── scripts/           # System scripts
│   └── vim-plugins/       # Custom Vim plugins
│
├── overlays/              # Nixpkgs overlays
├── templates/             # Module templates
├── secrets/               # Encrypted secrets
└── users/                 # User-specific configurations
```

## 💻 Supported Hosts

### 🖥️ Physical Machines

- **asus-zephyrus-gu603**: ASUS Zephyrus gaming laptop with NVIDIA graphics
- **dostov-dev**: Development workstation

### 🌐 Virtual Environments

- **wsl**: Windows Subsystem for Linux setup

## 🎨 Desktop Environments

This configuration supports multiple desktop environments:

- **Hyprland**: Wayland compositor with extensive customization
- **GNOME**: Traditional desktop environment
- **KDE Plasma**: Feature-rich desktop environment

## 🛠️ Development Environments

Pre-configured development shells for:

- **Kubernetes**: Container orchestration development
- **Laravel/PHP**: Web development with PHP and Laravel
- **Python**: Python development with common tools
- **Default**: General development environment

## 📦 Key Features

### 🔧 System Management

- **Impermanence**: Stateless system with persistent data management
- **Disko**: Declarative disk partitioning
- **Secrets**: Age-encrypted secrets management
- **Backups**: Automated backup solutions with Restic

### 🖥️ Desktop Experience

- **Hyprland**: Modern Wayland compositor with custom theming
- **HyprPanel**: Custom status bar and system panels
- **Stylix**: System-wide theming
- **Multiple browsers**: Firefox, Chromium, Zen Browser support

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
# Update all flake inputs
just update

# Update specific input
just update-input nixpkgs

# Rebuild system
just nix-upgrade switch

# Run tests
just test

# View all available commands
just --list
```

## 🔧 Customization

### 🏠 Adding a New Host

1. Create a new directory in `hosts/`
2. Add configuration files (`default.nix`, `hardware.nix`, etc.)
3. Update `hosts/default.nix` to include the new host
4. Rebuild with `just nix-upgrade switch`

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
- Referenced in `secrets.nix`

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
