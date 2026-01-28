# Shared Host Configurations

This directory contains shared configuration modules that can be reused across multiple hosts.

## Purpose

Instead of duplicating configuration in every host, place common configurations here and import them as needed.

## Structure

```
_shared/
├── presets/          # Configuration bundles for common host setups
│   ├── base/         # Essential base configuration (users, fonts, Home Manager, etc.)
│   ├── work/         # Work-related tools, containers, development packages
│   ├── personal/     # Personal apps and settings
│   └── linode/       # Linode-specific server configurations
└── README.md         # This file
```

## Using Presets

Presets are NixOS modules that bundle common configurations. Import them in your host's `default.nix`:

```nix
{
  imports = [
    ../_shared/presets/base
    ../_shared/presets/work
    ../_shared/presets/personal
    ./hardware.nix
  ];

  modules.presets = {
    base.enable = true;
    work.enable = true;
    personal.enable = true;
  };

  # Host-specific configuration...
}
```

## Available Presets

### Base (`presets/base/`)
Essential configuration for all hosts:
- User setup with nushell shell
- Common system packages (git, jq, ripgrep, curl, etc.)
- Fonts (Noto Fonts, Nerd Fonts)
- Home Manager integration
- Nix settings with flakes enabled
- System services (printing, gvfs, avahi)

### Work (`presets/work/`)
Development and work tools:
- Development packages (PHP, Node.js, Go, Bun, kubectl, gh)
- Work containers (Traefik, MySQL, Redis, Soketi, etc.)
- SSH configurations for work servers
- Development tools (mkcert, corepack)

### Personal (`presets/personal/`)
Personal apps and utilities:
- nix-alien for running unpatched binaries
- QMK firmware tools
- Personal containers (Homarr dashboard)
- Additional utilities (graphviz, yazi)

### Linode (`presets/linode/`)
Server-specific configurations for Linode VPS hosts.

---

*Note: Presets are for **host-level** configuration bundles. Use `modules/` for individual reusable feature modules.*
