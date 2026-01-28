# Shared Host Configurations

This directory contains shared configuration modules that can be reused across multiple hosts.

## Purpose

Instead of duplicating configuration in every host, place common configurations here and import them as needed.

## Structure

```
_shared/
├── base.nix          # Essential base configuration for all hosts
├── desktop.nix       # Common desktop environment settings
├── work.nix          # Work-related shared configuration
└── gaming.nix        # Gaming-related shared configuration
```

## Usage

Import shared configs in host `default.nix`:

```nix
{
  imports = [
    ../_ shared/base.nix
    ../_shared/desktop.nix
    ./hardware.nix
  ];

  # Host-specific configuration...
}
```

## Examples

### Base Configuration (base.nix)
Common settings for all hosts:
- Boot configuration
- Network defaults
- Base system packages
- Common services

### Desktop Configuration (desktop.nix)
Shared desktop settings:
- Display manager configuration
- Common desktop apps
- Fonts
- Theme settings

### Work Configuration (work.nix)
Development tools:
- IDEs
- Docker
- Development shells
- SSH/VPN configuration

---

*Note: Prefer using modules in `modules/` for feature configuration. Use `_shared/` for host-level configuration patterns.*
