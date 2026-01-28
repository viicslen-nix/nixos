# Module System Guide

This guide explains how the module system works in this NixOS configuration.

## Overview

Modules are the building blocks of this configuration. They encapsulate related functionality and can be easily enabled/disabled across different hosts.

## Module Organization

### NixOS Modules (`modules/nixos/`)

System-level modules organized by category:

- **`hardware/`** - Hardware-specific configurations
  - `intel` - Intel CPU optimizations
  - `nvidia` - NVIDIA GPU drivers and settings
  - `asus` - ASUS laptop-specific features
  - `bluetooth` - Bluetooth support
  - `display` - Display configuration

- **`desktop/`** - Desktop environments
  - `gnome` - GNOME desktop
  - `kde` - KDE Plasma desktop

- **`programs/`** - System programs
  - `docker` - Docker daemon
  - `steam` - Steam gaming platform
  - `one-password` - 1Password integration
  - `mullvad` - Mullvad VPN

- **`functionality/`** - System features
  - `sound` - Audio configuration
  - `network` - Networking setup
  - `theming` - System theming (Stylix)
  - `impermanence` - Stateless system persistence
  - `backups` - Backup configurations
  - `power-management` - Power optimization

- **`presets/`** - Configuration bundles
  - `base` - Essential system configuration
  - `work` - Work-oriented setup
  - `personal` - Personal use configuration

### Home Manager Modules (`modules/home-manager/`)

User-level modules:

- **`programs/`** - User applications
  - `git` - Git configuration
  - `firefox` - Firefox browser
  - `alacritty` - Terminal emulator
  - `nushell` - Nushell configuration
  - `tmux` - Terminal multiplexer
  - And many more...

- **`functionality/`** - User features
  - `impermanence` - User data persistence
  - `autostart` - Autostart applications
  - `home-manager` - HM configuration

- **`defaults/`** - Default user settings

## Using Modules

### Enable a Module

In your host configuration:

```nix
modules = {
  hardware.nvidia.enable = true;
  desktop.gnome.enable = true;
  programs.docker.enable = true;
};
```

### Configure a Module

Most modules accept additional options:

```nix
modules.programs.docker = {
  enable = true;
  nvidiaSupport = true;
  storageDriver = "btrfs";
  allowedTcpPorts = [ 80 443 8080 ];
};
```

### Using Presets

Presets bundle multiple modules:

```nix
modules.presets = {
  base.enable = true;     # Essential system setup
  work.enable = true;     # Work tools
  personal.enable = true; # Personal applications
};
```

## Creating Modules

### Quick Start

Use the generator:

```bash
just new-module nixos programs my-program
```

This creates a template at `modules/nixos/programs/my-program/default.nix`.

### Manual Creation

#### 1. Create Module File

Create `modules/nixos/programs/my-program/default.nix`:

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.programs.my-program;
in {
  options.modules.programs.my-program = {
    enable = mkEnableOption "my-program";
    
    package = mkOption {
      type = types.package;
      default = pkgs.my-program;
      description = "Package to use";
    };
    
    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Configuration settings";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    
    # Additional configuration...
  };
}
```

#### 2. Register Module

Add to `modules/nixos/default.nix`:

```nix
{
  programs = {
    # ... existing modules
    my-program = import ./programs/my-program;
  };
}
```

#### 3. Use in Host

```nix
modules.programs.my-program = {
  enable = true;
  settings = {
    option1 = "value1";
  };
};
```

## Module Patterns

### Basic Enable Pattern

```nix
options.modules.category.name = {
  enable = mkEnableOption "name";
};

config = mkIf cfg.enable {
  # configuration
};
```

### With Package Option

```nix
options.modules.category.name = {
  enable = mkEnableOption "name";
  package = mkPackageOption pkgs "package-name" {};
};

config = mkIf cfg.enable {
  environment.systemPackages = [ cfg.package ];
};
```

### With Settings

```nix
options.modules.category.name = {
  enable = mkEnableOption "name";
  
  settings = mkOption {
    type = types.attrs;
    default = {};
    description = "Configuration settings";
  };
};

config = mkIf cfg.enable {
  programs.name.settings = cfg.settings;
};
```

### With Conditional Features

```nix
options.modules.category.name = {
  enable = mkEnableOption "name";
  
  feature = mkOption {
    type = types.bool;
    default = false;
    description = "Enable special feature";
  };
};

config = mkIf cfg.enable {
  # Base configuration
  
  # Conditional feature
  extraConfig = mkIf cfg.feature {
    # ... additional configuration
  };
};
```

## Best Practices

### 1. Naming Conventions

- Use descriptive names: `programs.docker`, not `programs.d`
- Follow existing patterns in the category
- Use kebab-case for multi-word names: `one-password`

### 2. Option Definitions

- Always provide `description` for options
- Use appropriate types (`types.bool`, `types.str`, `types.attrs`)
- Provide sensible defaults
- Document valid values in description

### 3. Conditional Configuration

- Use `mkIf` for optional configuration
- Use `mkMerge` for combining configs
- Use `mkDefault` for overridable defaults

### 4. Dependencies

- Declare module dependencies clearly
- Use assertions for required options
- Provide helpful error messages

```nix
config = mkIf cfg.enable {
  assertions = [{
    assertion = config.virtualisation.docker.enable;
    message = "Docker must be enabled for this module";
  }];
};
```

### 5. Persistence Integration

For impermanence support:

```nix
config = mkIf cfg.enable {
  # ... main config
  
  # Persistence
  home-manager.users.${user} = {
    modules.functionality.impermanence = {
      directories = [ ".local/share/my-program" ];
      config = [ "my-program" ];
    };
  };
};
```

## Module Testing

### Build Test

```bash
just build <host>
```

### Dry Run

```bash
nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run
```

### Evaluate Module

```bash
nix eval .#nixosConfigurations.<host>.config.modules.category.name
```

## Troubleshooting

### Module Not Found

1. Check module is imported in `modules/nixos/default.nix` or `modules/home-manager/default.nix`
2. Verify path is correct
3. Check for syntax errors: `just check-file <file>`

### Option Conflicts

If two modules define the same option:
- Use `mkDefault` for default values
- Use `mkForce` to override (carefully)
- Use `mkMerge` to combine configurations

### Circular Dependencies

Avoid circular module dependencies:
- Don't import modules that import each other
- Use `mkIf` to break dependency chains
- Restructure shared logic into library functions

## Advanced Topics

### Automatic Module Discovery

This configuration uses a **fully recursive auto-import system** that eliminates manual module registration boilerplate.

#### How It Works

Modules are automatically discovered and registered based on their file system location:

```
modules/nixos/programs/docker/default.nix
└─> Available as: nixosModules.programs.docker
└─> Used as: modules.programs.docker.enable = true;

modules/home-manager/programs/firefox/default.nix
└─> Available as: homeManagerModules.programs.firefox
└─> Used as: modules.programs.firefox.enable = true;
```

#### Unlimited Nesting Depth

The system supports arbitrary nesting levels:

```
modules/nixos/programs/web/browsers/firefox/default.nix
└─> nixosModules.programs.web.browsers.firefox

modules/nixos/services/monitoring/prometheus/exporters/node/default.nix
└─> nixosModules.services.monitoring.prometheus.exporters.node
```

#### Exclusion Rules

The auto-import system **automatically excludes**:
- Hidden files/directories (starting with `.`)
- Special directories (starting with `_`, like `_shared/`)
- Documentation files (`*.md`, `*.txt`, `*.rst`)
- The special `all.nix` file (manually imported)
- Files with extensions (only `default.nix` and directories are considered)

#### Hybrid Directories

Some directories contain **both** a `default.nix` file AND subdirectories:

```
containers/
├── default.nix           # Parent module with shared settings
├── postgres/default.nix  # Child module
├── mysql/default.nix     # Child module
└── redis/default.nix     # Child module
```

In this pattern:
- `containers/default.nix` is discovered as `nixosModules.containers`
- The parent module manually imports its children using `imports = [./postgres ./mysql ...]`
- Children access parent settings: `config.modules.containers.settings.log-driver`
- Usage: `modules.containers.postgres.enable = true;`

**Why this pattern?** NixOS modules are functions, not attribute sets. They can't be automatically merged with `//`, so parent modules must explicitly import their children to compose them properly.

#### No Registration Required

When creating new modules:

1. ✅ Create the module file:
   ```bash
   just new-module nixos programs my-app
   ```

2. ✅ Use it immediately:
   ```nix
   modules.programs.my-app.enable = true;
   ```

3. ❌ **NO** manual registration needed in `default.nix`

The module is automatically discovered and available!

#### Implementation Details

Located in `lib/modules.nix`:

```nix
autoImportRecursive = path:
  # Recursively imports all modules from a directory tree
  # Returns nested attribute sets matching directory structure
```

Used in `modules/nixos/default.nix` and `modules/home-manager/default.nix`:

```nix
let
  autoImported = modulesLib.autoImportRecursive ./.;
in
  autoImported // {
    # Manual imports for special cases
    all = import ./all.nix;
  }
```

### Module Arguments

Access special arguments in modules:

```nix
{ config, lib, pkgs, inputs, outputs, hostName, ... }:
```

- `config` - Full system configuration
- `lib` - Nixpkgs library functions
- `pkgs` - Package set
- `inputs` - Flake inputs
- `outputs` - Flake outputs
- `hostName` - Current host name

---

*See also: [STRUCTURE.md](./STRUCTURE.md) for overall organization*
