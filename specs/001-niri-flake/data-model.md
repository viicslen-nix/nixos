# Data Model: Extract Niri Desktop Configuration to Separate Flake

**Feature**: 001-niri-flake
**Date**: 2025-11-05

## Overview

This document describes the structure and relationships of the niri flake components. Since this is a configuration migration rather than a data-driven application, the "data model" represents the module structure, flake outputs, and configuration entities.

---

## Entity 1: Niri Flake

**Purpose**: Standalone flake that encapsulates all niri desktop environment configuration

**Location**: `flakes/niri/`

**Attributes**:
- `description`: Human-readable flake description
- `inputs`: Flake dependencies (nixpkgs, niri-flake, dankMaterialShell ecosystem)
- `outputs`: Exposed NixOS modules

**Structure**:
```nix
{
  description = "Niri desktop environment configuration";

  inputs = {
    nixpkgs = { type = "github", follows = "nixpkgs" };
    niri-flake = { type = "github", url = "sodiboo/niri-flake" };
    dgop = { type = "github", url = "AvengeMedia/dgop" };
    dms-cli = { type = "github", url = "AvengeMedia/danklinux" };
    dankMaterialShell = {
      type = "github",
      url = "AvengeMedia/DankMaterialShell",
      depends-on = [dgop, dms-cli]
    };
  };

  outputs = {
    nixosModules.default = NiriModule;
    nixosModules.niri = NiriModule;  // Alias for clarity
  };
}
```

**Relationships**:
- Depends on: nixpkgs, niri-flake, dankMaterialShell ecosystem
- Consumed by: Main NixOS flake (via path input)
- Exposes: NixOS module through outputs

**Validation Rules**:
- All inputs must follow nixpkgs for consistency
- Must provide at least `nixosModules.default` output
- flake.lock must exist and be tracked in git

---

## Entity 2: Niri NixOS Module

**Purpose**: Main NixOS module that defines niri desktop environment options and configuration

**Location**: `flakes/niri/default.nix`

**Attributes**:
- `options.modules.desktop.niri.enable`: Boolean to enable niri
- `options.modules.desktop.niri.terminal`: Optional package for default terminal
- `options.modules.desktop.niri.browser`: Optional package for default browser
- `options.modules.desktop.niri.editor`: Optional package for default editor
- `options.modules.desktop.niri.fileManager`: Optional package for default file manager
- `options.modules.desktop.niri.passwordManager`: Optional package for default password manager

**Structure**:
```nix
{
  options = {
    modules.desktop.niri = {
      enable = mkEnableOption "niri desktop";
      terminal = mkOption { type = nullOr package; default = null; };
      browser = mkOption { type = nullOr package; default = null; };
      editor = mkOption { type = nullOr package; default = null; };
      fileManager = mkOption { type = nullOr package; default = null; };
      passwordManager = mkOption { type = nullOr package; default = null; };
    };
  };

  config = mkIf cfg.enable {
    programs.niri.enable = true;
    home-manager.sharedModules = [
      ./binds.nix
      ./rules.nix
      ./settings.nix
      ./shell.nix
    ];
  };
}
```

**Relationships**:
- Imports: niri-flake.nixosModules.niri (via inputs)
- Includes: binds.nix, rules.nix, settings.nix, shell.nix (as home-manager shared modules)
- Consumed by: Host configurations

**Validation Rules**:
- `enable` must be false by default (explicit opt-in)
- All package options must accept `null` (for fallback pattern)
- Must check for home-manager availability before injecting sharedModules
- Must use `mkIf cfg.enable` to conditionally apply configuration

**State Transitions**:
1. Disabled (default) → Enabled (user sets `enable = true`)
2. Enabled → Configured (user sets application options)
3. Configured → Active (system rebuild applies configuration)

---

## Entity 3: Keybindings Module

**Purpose**: Defines niri keybindings with preference fallback pattern

**Location**: `flakes/niri/binds.nix`

**Attributes**:
- `terminal`: Resolved terminal application (from cfg or defaults or null)
- `browser`: Resolved browser application
- `editor`: Resolved editor application
- `fileManager`: Resolved file manager application
- `passwordManager`: Resolved password manager application (with --quick-access flag)

**Structure**:
```nix
{
  programs.niri.settings.binds = {
    "Mod+Return" = spawn terminal;        // If terminal != null
    "Mod+B" = spawn browser;              // If browser != null
    "Mod+E" = spawn fileManager;          // If fileManager != null
    "Ctrl+Shift+Space" = sh passwordManager;  // If passwordManager != null

    // Workspace bindings (1-10)
    "Mod+{1-0}" = focus-workspace {1-10};
    "Mod+Shift+{1-0}" = move-column-to-workspace {1-10};

    // Window management
    "Mod+Q" = close-window;
    "Mod+T" = toggle-window-floating;
    // ... (all other bindings)
  };
}
```

**Relationships**:
- Reads from: osConfig.modules.desktop.niri.* options
- Falls back to: config.modules.functionality.defaults.* options
- Consumed by: home-manager as shared module

**Validation Rules**:
- Must handle null values gracefully (use `optionalAttrs`)
- Must resolve preferences in order: cfg → defaults → null
- Must use `getExe` for package paths
- Password manager must append `--quick-access` flag

---

## Entity 4: Window Rules Module

**Purpose**: Defines window and layer rules for niri compositor

**Location**: `flakes/niri/rules.nix`

**Attributes**:
- `window-rules`: List of window-specific rules
- `layer-rules`: List of layer-specific rules

**Structure**:
```nix
{
  programs.niri.settings = {
    window-rules = [
      {
        geometry-corner-radius = { all-corners = 8.0 };
        clip-to-geometry = true;
      },
      {
        matches = [{ app-id = "ferdium"; }];
        default-column-width = { proportion = 0.5 };
        open-floating = true;
        // ... (ferdium-specific rules)
      }
    ];

    layer-rules = [
      {
        matches = [{ namespace = "dms:blurwallpaper"; }];
        place-within-backdrop = true;
      }
    ];
  };
}
```

**Relationships**:
- Standalone configuration (no external dependencies)
- Consumed by: home-manager as shared module

**Validation Rules**:
- All rules must have valid niri rule syntax
- App-id matches must be strings
- Numeric values (corner radius, proportions) must be floats

---

## Entity 5: General Settings Module

**Purpose**: Configures niri compositor settings and startup applications

**Location**: `flakes/niri/settings.nix`

**Attributes**:
- Compositor preferences (CSD, hotkey overlay, screenshots)
- Cursor behavior (hiding, warping)
- Input settings (focus-follows-mouse, warp-mouse-to-focus)
- Layout settings (gaps, borders, column widths)
- Startup applications (polkit, gnome-keyring, password manager)

**Structure**:
```nix
{
  programs.niri.settings = {
    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/%Y-%m-%dT%H%M%S.png";

    cursor = {
      hide-when-typing = true;
      hide-after-inactive-ms = 2000;
    };

    input = {
      warp-mouse-to-focus = { enable = true; mode = "center-xy"; };
      focus-follows-mouse = { enable = true; };
    };

    layout = {
      gaps = 16;
      border.width = 4;
      preset-column-widths = [0.3, 0.48, 0.65, 0.95];
      default-column-width = 0.95;
    };

    spawn-at-startup = [
      polkit-agent,
      gnome-keyring,
      passwordManager
    ];
  };
}
```

**Relationships**:
- Reads from: osConfig.modules.desktop.niri.passwordManager (for startup)
- Depends on: pkgs for polkit_gnome, gnome-keyring, xwayland-satellite
- Consumed by: home-manager as shared module

**Validation Rules**:
- Password manager must be resolved via fallback pattern
- All startup commands must exist in pkgs
- Layout proportions must be between 0.0 and 1.0

---

## Entity 6: Shell Integration Module

**Purpose**: Configures DankMaterialShell for niri desktop environment

**Location**: `flakes/niri/shell.nix`

**Attributes**:
- DankMaterialShell enable flag
- Niri-specific shell configuration
- Stylix theme integration

**Structure**:
```nix
{
  imports = [
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
  ];

  programs.dankMaterialShell = {
    enable = true;
    niri = {
      enableSpawn = true;
      enableKeybinds = true;
    };
  };

  xdg.configFile."DankMaterialShell/stylix.json".source =
    mkIf config.stylix.enable (generateStylixTheme config.lib.stylix.colors);
}
```

**Relationships**:
- Imports: dankMaterialShell home modules
- Reads from: config.stylix.enable and config.lib.stylix.colors
- Consumed by: home-manager as shared module

**Validation Rules**:
- Must import both default and niri DankMaterialShell modules
- Stylix integration only active if stylix enabled
- Theme JSON must match DankMaterialShell schema

---

## Entity 7: Main Flake Input Reference

**Purpose**: Local path input in main flake.nix that references the niri flake

**Location**: `/etc/nixos/flake.nix` (inputs section)

**Attributes**:
- `url`: Path to local niri flake (`"path:./flakes/niri"`)
- `inputs.nixpkgs.follows`: Follow main flake's nixpkgs

**Structure**:
```nix
{
  inputs = {
    // ... other inputs

    niri = {
      url = "path:./flakes/niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    // Remove these (moved to niri flake):
    // niri-flake = { ... };
    // dankMaterialShell = { ... };
    // dgop = { ... };
    // dms-cli = { ... };
  };
}
```

**Relationships**:
- References: Niri flake (Entity 1)
- Follows: Main flake nixpkgs for consistency
- Used by: Host configurations

**Validation Rules**:
- URL must be valid path reference
- Must follow main nixpkgs input
- Path must exist before system rebuild

---

## Module Dependency Graph

```
Main Flake (flake.nix)
  │
  └─→ inputs.niri (path:./flakes/niri)
        │
        ├─→ Niri Flake (flakes/niri/flake.nix)
        │     │
        │     ├─→ inputs.niri-flake (upstream niri compositor)
        │     ├─→ inputs.dankMaterialShell
        │     ├─→ inputs.dgop
        │     └─→ inputs.dms-cli
        │
        └─→ nixosModules.default (flakes/niri/default.nix)
              │
              ├─→ imports: inputs.niri-flake.nixosModules.niri
              │
              └─→ home-manager.sharedModules:
                    ├─→ binds.nix (keybindings)
                    ├─→ rules.nix (window/layer rules)
                    ├─→ settings.nix (compositor settings)
                    └─→ shell.nix (DankMaterialShell)
                          │
                          └─→ imports: inputs.dankMaterialShell.homeModules
```

---

## Configuration Flow

1. **Host enables niri**: `modules.desktop.niri.enable = true;` in `hosts/<hostname>/default.nix`
2. **Main flake loads niri**: Via `inputs.niri` path reference
3. **Niri module activates**: `default.nix` enables `programs.niri.enable = true`
4. **Upstream niri loads**: Via `inputs.niri-flake` import in niri flake
5. **Home manager modules inject**: All 4 config files added as sharedModules
6. **Per-user config applies**: Each user gets niri settings, binds, rules, shell
7. **System rebuilds**: NixOS applies all configuration atomically

---

## Migration Impact

**Files Moving**:
- `modules/nixos/desktop/niri/default.nix` → `flakes/niri/default.nix`
- `modules/nixos/desktop/niri/binds.nix` → `flakes/niri/binds.nix`
- `modules/nixos/desktop/niri/rules.nix` → `flakes/niri/rules.nix`
- `modules/nixos/desktop/niri/settings.nix` → `flakes/niri/settings.nix`
- `modules/nixos/desktop/niri/shell.nix` → `flakes/niri/shell.nix`

**New Files Created**:
- `flakes/niri/flake.nix` (new flake definition)
- `flakes/niri/flake.lock` (new dependency lock file)

**Files Modified**:
- `/etc/nixos/flake.nix` (update inputs section)
- Potentially `hosts/<hostname>/default.nix` (if explicit import paths used)

**Files Removed**:
- `modules/nixos/desktop/niri/` directory (entire directory deleted)

---

## Summary

The niri flake structure follows NixOS module best practices:
- Single flake output (nixosModules.default)
- Clear module separation (5 focused configuration files)
- Preference fallback pattern for flexibility
- Home manager integration for per-user config
- Independent dependency management

This structure enables the three user stories:
- P1: Isolated management via separate flake
- P2: Version independence via dedicated flake.lock
- P3: Reusability via standard flake outputs
