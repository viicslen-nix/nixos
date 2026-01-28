# NixOS Configuration Structure

This document explains the structure and organization of this NixOS configuration.

## Directory Layout

```
.
├── flake.nix              # Main flake configuration with inputs/outputs
├── flake.lock             # Locked dependency versions
├── Justfile               # Task runner with common commands
│
├── docs/                  # Documentation (you are here!)
│   ├── STRUCTURE.md       # Repository structure (this file)
│   ├── MODULES.md         # Module system guide
│   ├── ADDING_HOSTS.md    # How to add new hosts
│   ├── SECRETS.md         # Secrets management guide
│   └── DEVELOPMENT.md     # Development workflow
│
├── lib/                   # Custom library functions
│   ├── default.nix        # Main library exports
│   └── ...                # Helper functions for config building
│
├── modules/               # Reusable NixOS and Home Manager modules
│   ├── nixos/             # NixOS system modules (auto-discovered)
│   │   ├── hardware/      # Hardware-specific configs (Intel, NVIDIA, etc.)
│   │   ├── desktop/       # Desktop environments (GNOME, KDE, etc.)
│   │   ├── programs/      # System programs (Docker, Steam, etc.)
│   │   ├── core/          # Core system features (sound, network, theming)
│   │   ├── services/      # System services (impermanence, backups, power)
│   │   ├── features/      # Optional features (app-images, VMs, etc.)
│   │   └── containers/    # Container configurations
│   │
│   └── home-manager/      # Home Manager user modules (auto-discovered)
│       ├── programs/      # User programs (git, firefox, alacritty, etc.)
│       └── functionality/ # User features (impermanence, autostart)

├── hosts/                 # Host-specific configurations
│   ├── default.nix        # Host registry and shared config
│   ├── _shared/           # Shared host configurations
│   │   └── presets/       # Host configuration presets (base, work, personal)
│   ├── home-desktop/      # Desktop workstation
│   ├── asus-zephyrus-gu603/  # Gaming laptop
│   ├── dostov-dev/        # Development server
│   ├── lenovo-legion-go/  # Handheld gaming device
│   └── wsl/               # Windows Subsystem for Linux
│
├── packages/              # Custom package definitions
│   └── by-name/           # Packages organized by name
│
├── dev-shells/            # Development environments
│   ├── default.nix        # Default dev shell
│   ├── kubernetes.nix     # Kubernetes development
│   ├── laravel.nix        # PHP/Laravel development
│   └── python.nix         # Python development
│
├── flakes/                # Custom flakes for complex components
│   ├── neovim/            # Neovim configuration flake
│   ├── hyprland/          # Hyprland compositor flake
│   ├── niri/              # Niri window manager flake
│   └── ...
│
├── overlays/              # Nixpkgs overlays
├── secrets/               # Encrypted secrets (agenix)
├── templates/             # Module templates
├── tools/                 # Development helper scripts
└── users/                 # User-specific configurations
```

## Configuration Flow

### 1. Flake Entry Point (`flake.nix`)

The flake defines:
- **inputs**: External dependencies (nixpkgs, home-manager, etc.)
- **outputs**: What this flake provides (packages, modules, configurations)

### Library Functions (`lib/`)

Custom helper functions for:
- Building NixOS configurations
- Managing impermanence
- **Auto-discovering modules recursively** (`lib/modules.nix`)
- System generation utilities

The auto-import system in `lib/modules.nix` provides:
- `autoImportRecursive` - Recursively imports all modules from a directory tree
- Smart exclusion patterns for special files/directories
- Support for hybrid directories (modules that import sub-modules)

### 3. Modules (`modules/`)

Reusable configuration modules organized by:
- **Purpose**: What they configure (programs, hardware, features)
- **Level**: System (nixos) vs User (home-manager)

Each module:
- Defines options under `modules.*` namespace
- Uses `enable` option pattern
- Configures when enabled

### Hosts (`hosts/`)

Each host directory contains:
- `default.nix` - Main configuration
- `hardware.nix` - Hardware-specific settings (optional)
- `disko.nix` - Disk partitioning (optional)
- `home.nix` - User-specific overrides (optional)

The `_shared/` directory contains:
- `presets/` - Reusable host configuration bundles (base, work, personal)
- Other shared host-level configurations

**Using Presets:**
Presets are specified centrally in `hosts/default.nix`:

```nix
# hosts/default.nix
{
  hosts = {
    my-host = {
      system = "x86_64-linux";
      path = ./my-host;
      presets = ["base" "work" "personal"];  # Centralized preset configuration
    };
  };
}
```

No need to import presets in individual host files! Just list them in the host definition, and they'll be automatically imported by `mkNixosConfigurations`.

Hosts are registered in `hosts/default.nix` and built via `mkNixosConfigurations`.

### 5. Packages (`packages/`)

Custom packages using the `by-name/` structure for automatic discovery.

## Module System

### Automatic Module Discovery

**This configuration uses fully recursive auto-import** - modules are automatically discovered based on their file system location, eliminating the need for manual registration.

#### How It Works

```
modules/nixos/programs/docker/default.nix
└─> Automatically available as: nixosModules.programs.docker
└─> Used as: modules.programs.docker.enable = true;
```

The system recursively scans all directories, creating nested attribute sets that match the directory structure. No manual imports needed!

#### Directory Organization

Modules are organized into logical categories:

**NixOS Modules (`modules/nixos/`):**
- `hardware/` - Hardware configs (auto-discovered: `modules.hardware.*`)
- `desktop/` - Desktop environments (`modules.desktop.*`)
- `programs/` - System programs (`modules.programs.*`)
- `core/` - Essential features like sound, network, theming (`modules.core.*`)
- `services/` - System services like impermanence, backups (`modules.services.*`)
- `features/` - Optional features like VMs, app-images (`modules.features.*`)
- `containers/` - Container definitions (`modules.containers.*`)

**Home Manager Modules (`modules/home-manager/`):**
- `programs/` - User programs (`modules.programs.*`)
- `functionality/` - User features (`modules.functionality.*`)

**Host Presets (`hosts/_shared/presets/`):**
- `base/` - Essential system setup (users, fonts, Home Manager, etc.)
- `work/` - Work-related tools, containers, and development packages
- `personal/` - Personal apps and settings
- `linode/` - Linode-specific configurations

Presets are imported directly in host configs and enabled via `modules.presets.*`.

#### Unlimited Nesting

The system supports arbitrary nesting depth:

```
modules/nixos/services/monitoring/prometheus/exporters/node/default.nix
└─> nixosModules.services.monitoring.prometheus.exporters.node
```

#### Smart Exclusions

Automatically excludes:
- Hidden files/directories (`.git`, `.vscode`)
- Special directories (`_shared/`, `_lib/`)
- Documentation files (`*.md`, `*.txt`)
- The `all.nix` file (manually imported separately)

### Module Namespace

All modules use the `modules.*` namespace:

```nix
modules = {
  hardware.nvidia.enable = true;
  desktop.gnome.enable = true;
  programs.docker.enable = true;
  functionality.theming.enable = true;
};
```

### Module Structure

```nix
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.category.name;
in {
  options.modules.category.name = {
    enable = mkEnableOption "name";
    # ... more options
  };

  config = mkIf cfg.enable {
    # ... configuration
  };
}
```

## Building and Deploying

### Build a Configuration
```bash
just build home-desktop
```

### Deploy to System
```bash
just switch
```

### Update Flake Inputs
```bash
just update
```

## Adding New Components

### Add a Module

Modules are **automatically discovered** - just create the file:

```bash
just new-module nixos programs my-program
```

The module is immediately available as `modules.programs.my-program`! No manual registration required.

For nested modules:
```bash
just new-module nixos services monitoring prometheus
```

Available as `modules.services.monitoring.prometheus`.

### Add a Host
1. Create `hosts/my-host/` directory
2. Add `default.nix` configuration
3. Register in `hosts/default.nix`
4. Build: `just build my-host`

### Add a Package
1. Create `packages/by-name/my-package/package.nix`
2. Build: `nix build .#my-package`

## Best Practices

1. **Modularity**: Keep modules focused and reusable
2. **Enable Options**: Always use `enable` for optional features
3. **Documentation**: Comment complex configurations
4. **Testing**: Build before deploying (`just build <host>`)
5. **Commits**: Use meaningful commit messages

## Learn More

- [MODULES.md](./MODULES.md) - Detailed module system guide
- [ADDING_HOSTS.md](./ADDING_HOSTS.md) - Step-by-step host creation
- [SECRETS.md](./SECRETS.md) - Managing secrets with agenix
- [DEVELOPMENT.md](./DEVELOPMENT.md) - Development workflow

---

*For questions or improvements, see the main README.md*
