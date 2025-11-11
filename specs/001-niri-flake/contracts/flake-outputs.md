# Niri Flake Output Contract

**Feature**: 001-niri-flake
**Date**: 2025-11-05
**Version**: 1.0.0

## Overview

This document defines the contract for the niri flake outputs. It specifies what consumers of the flake can expect to be exposed and how to use it.

---

## Flake Outputs Schema

### nixosModules.default

**Type**: NixOS Module

**Purpose**: Main niri desktop environment module with all configuration

**Usage**:
```nix
# In main flake.nix
inputs.niri.nixosModules.default

# Or in host configuration
imports = [ inputs.niri.nixosModules.default ];
```

**Provides**:
- Module option namespace: `config.modules.desktop.niri`
- Automatic home-manager shared modules injection
- Integration with upstream niri-flake

---

### nixosModules.niri

**Type**: Alias to nixosModules.default

**Purpose**: Named alias for clarity and discoverability

**Usage**:
```nix
inputs.niri.nixosModules.niri
```

**Note**: Identical to `nixosModules.default`, provided for semantic clarity

---

## Module Options Contract

### modules.desktop.niri.enable

**Type**: `boolean`
**Default**: `false`
**Description**: Enable the niri desktop environment

**Example**:
```nix
modules.desktop.niri.enable = true;
```

---

### modules.desktop.niri.terminal

**Type**: `null or package`
**Default**: `null`
**Description**: Default terminal emulator for niri keybindings

**Fallback Behavior**:
1. If set: Use this package
2. If null: Fall back to `config.modules.functionality.defaults.terminal`
3. If still null: Skip terminal keybinding

**Example**:
```nix
modules.desktop.niri.terminal = pkgs.alacritty;
```

---

### modules.desktop.niri.browser

**Type**: `null or package`
**Default**: `null`
**Description**: Default web browser for niri keybindings

**Fallback Behavior**:
1. If set: Use this package
2. If null: Fall back to `config.modules.functionality.defaults.browser`
3. If still null: Skip browser keybinding

**Example**:
```nix
modules.desktop.niri.browser = pkgs.firefox;
```

---

### modules.desktop.niri.editor

**Type**: `null or package`
**Default**: `null`
**Description**: Default text editor for niri keybindings

**Fallback Behavior**:
1. If set: Use this package
2. If null: Fall back to `config.modules.functionality.defaults.editor`
3. If still null: Skip editor keybinding

**Example**:
```nix
modules.desktop.niri.editor = pkgs.neovim;
```

---

### modules.desktop.niri.fileManager

**Type**: `null or package`
**Default**: `null`
**Description**: Default file manager for niri keybindings

**Fallback Behavior**:
1. If set: Use this package
2. If null: Fall back to `config.modules.functionality.defaults.fileManager`
3. If still null: Skip file manager keybinding

**Example**:
```nix
modules.desktop.niri.fileManager = pkgs.nautilus;
```

---

### modules.desktop.niri.passwordManager

**Type**: `null or package`
**Default**: `null`
**Description**: Default password manager for niri keybindings and startup

**Fallback Behavior**:
1. If set: Use this package
2. If null: Fall back to `config.modules.functionality.defaults.passwordManager`
3. If still null: Skip password manager keybinding and startup

**Special Handling**:
- Keybinding appends `--quick-access` flag
- Added to `spawn-at-startup` with `--silent` flag

**Example**:
```nix
modules.desktop.niri.passwordManager = pkgs.keepassxc;
```

---

## Input Dependencies

The niri flake declares these inputs (internal to flake, not exposed to consumers):

### Required Inputs

| Input | URL | Purpose |
|-------|-----|---------|
| `nixpkgs` | `github:NixOS/nixpkgs/nixos-unstable` | Base package set |
| `niri-flake` | `github:sodiboo/niri-flake` | Upstream niri compositor module |
| `dankMaterialShell` | `github:AvengeMedia/DankMaterialShell` | Niri shell/panel |
| `dgop` | `github:AvengeMedia/dgop` | DankMaterialShell dependency |
| `dms-cli` | `github:AvengeMedia/danklinux` | DankMaterialShell dependency |

### Input Following

All inputs follow the consumer's nixpkgs:
```nix
inputs.nixpkgs.follows = "nixpkgs";
```

---

## Integration Contract

### Main Flake Integration

**Required Changes**:

1. Add niri as path input:
```nix
inputs.niri = {
  url = "path:./flakes/niri";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

2. Import module in host:
```nix
# Option 1: Via imports
imports = [ inputs.niri.nixosModules.default ];

# Option 2: Via flake nixosConfigurations (handled automatically)
```

3. Enable in host configuration:
```nix
modules.desktop.niri.enable = true;
```

**Removed from Main Flake**:
- `inputs.niri-flake` (now in niri flake)
- `inputs.dankMaterialShell` (now in niri flake)
- `inputs.dgop` (now in niri flake)
- `inputs.dms-cli` (now in niri flake)

---

### Home Manager Integration

**Automatic**: When `modules.desktop.niri.enable = true` and home-manager available

**Injected Modules**:
1. `binds.nix` - Keybindings with preference fallbacks
2. `rules.nix` - Window and layer rules
3. `settings.nix` - Compositor settings and startup apps
4. `shell.nix` - DankMaterialShell integration

**User Impact**: None - integration is transparent

---

## Behavioral Contract

### Build Requirements

- **Must pass**: `nix flake check`
- **Must build**: `nix build ./flakes/niri`
- **Must evaluate**: Without errors in isolation

### Runtime Requirements

- **Must preserve**: All existing niri functionality
- **Must maintain**: Identical keybindings
- **Must support**: All window rules and settings
- **Must integrate**: With home-manager transparently

### Update Contract

- **Independent updates**: `cd flakes/niri && nix flake update`
- **Isolated changes**: Main flake.lock unaffected by niri updates
- **Backward compatible**: Option interface remains stable

---

## Versioning Contract

### Breaking Changes

Changes requiring MAJOR version bump:
- Removing or renaming module options
- Changing option types
- Removing flake outputs
- Incompatible option behavior changes

### Non-Breaking Changes

Changes allowing MINOR version bump:
- Adding new module options (with defaults)
- Adding new flake outputs
- Internal refactoring (same interface)

### Patch Changes

- Bug fixes in keybindings
- Documentation updates
- Dependency version updates (within nixpkgs pin)

---

## Compatibility Guarantees

### What is Guaranteed

- Module option namespace: `config.modules.desktop.niri.*`
- Flake output: `nixosModules.default`
- Preference fallback pattern behavior
- Home manager automatic integration
- All existing keybindings and window rules

### What is Not Guaranteed

- Internal module structure
- File organization within flake
- Dependency versions (managed by flake.lock)
- Upstream niri-flake changes

---

## Testing Contract

### Flake Validation

```bash
# Must pass all checks
nix flake check ./flakes/niri

# Must show outputs
nix flake show ./flakes/niri

# Expected output:
# github:user/repo?path=flakes/niri
# └───nixosModules
#     ├───default: NixOS module
#     └───niri: NixOS module
```

### Integration Validation

```bash
# Must build without errors
nixos-rebuild build --flake .#<hostname>

# Must switch without errors
nixos-rebuild switch --flake .#<hostname>

# Must preserve functionality (manual testing required)
# - All keybindings work
# - Window rules apply
# - DankMaterialShell loads
# - Startup apps launch
```

---

## Migration Notes

### For Existing Users

No changes required to host configurations if:
- Using `modules.desktop.niri.enable = true` (already correct)
- Not directly importing niri module files (using enable option)

Possible changes required if:
- Directly importing `modules/nixos/desktop/niri/*` (update import paths)
- Overriding niri module internals (restructure overrides)

### For New Users

Standard flake consumption pattern:
1. Add niri flake input
2. Import module in host
3. Enable with `modules.desktop.niri.enable = true`
4. Optionally set application preferences

---

## Examples

### Minimal Configuration

```nix
{
  modules.desktop.niri.enable = true;
}
```

Result: Niri enabled with no keybindings (all applications null)

### Full Configuration

```nix
{
  modules.desktop.niri = {
    enable = true;
    terminal = pkgs.alacritty;
    browser = pkgs.firefox;
    editor = pkgs.neovim;
    fileManager = pkgs.nautilus;
    passwordManager = pkgs.keepassxc;
  };
}
```

Result: Niri enabled with all keybindings configured

### Using Defaults

```nix
{
  modules.functionality.defaults = {
    terminal = pkgs.kitty;
    browser = pkgs.chromium;
  };

  modules.desktop.niri = {
    enable = true;
    # Inherits terminal and browser from defaults
    editor = pkgs.vscode;  # Override editor specifically
  };
}
```

Result: Niri uses kitty and chromium from defaults, vscode as editor override

---

## Support and Issues

### Reporting Issues

When reporting issues with the niri flake:
1. Specify flake version (git commit or flake.lock hash)
2. Include `nix flake metadata ./flakes/niri` output
3. Provide `nixos-rebuild` error output if applicable
4. Note which host configuration affected

### Debugging

```bash
# Check flake evaluation
nix eval ./flakes/niri#nixosModules.default

# Check option resolution
nixos-option modules.desktop.niri

# Inspect flake inputs
nix flake metadata ./flakes/niri
```

---

## Contract Version

**Version**: 1.0.0
**Status**: Initial contract definition
**Date**: 2025-11-05

This contract is binding for all consumers of the niri flake and will be maintained according to semantic versioning principles.
