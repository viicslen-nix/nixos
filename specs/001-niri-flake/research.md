# Research: Extract Niri Desktop Configuration to Separate Flake

**Feature**: 001-niri-flake
**Date**: 2025-11-05
**Status**: Complete

## Overview

This document consolidates research findings for extracting the niri desktop configuration into a standalone flake. The research focuses on flake structure patterns, module exposure mechanisms, and dependency management strategies.

---

## Research Area 1: Nix Flake Structure for NixOS Modules

### Decision: Use flake-parts or Simple Flake Structure

**Chosen**: Simple flake structure without flake-parts

**Rationale**:
- The existing `flakes/neovim/` uses flake-parts, but niri module is simpler
- Niri configuration doesn't need per-system builds or complex outputs
- Simple structure is more maintainable for pure module distribution
- Reduces dependencies (no flake-parts required)
- Easier to understand for future modifications

**Alternatives Considered**:
1. **flake-parts** (like neovim flake)
   - Pros: Consistent with existing pattern, handles multi-system outputs elegantly
   - Cons: Overkill for module-only flake, adds complexity, extra dependency

2. **Simple flake structure**
   - Pros: Minimal dependencies, clear and direct, sufficient for module outputs
   - Cons: Slightly different from neovim pattern

3. **flake-utils**
   - Pros: Lighter than flake-parts, still provides helpers
   - Cons: Unnecessary for module-only outputs

**Implementation Pattern**:
```nix
{
  description = "Niri desktop environment configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Additional dankMaterialShell dependencies...
  };

  outputs = { self, nixpkgs, niri-flake, dankMaterialShell, ... }: {
    nixosModules.default = import ./default.nix;
    nixosModules.niri = self.nixosModules.default;
  };
}
```

---

## Research Area 2: Module Import and Home Manager Integration

### Decision: Preserve Home Manager Shared Modules Pattern

**Chosen**: Keep home-manager sharedModules injection in main module

**Rationale**:
- Current pattern in default.nix works well: `home-manager.sharedModules = [./binds.nix ...]`
- Maintains encapsulation - niri flake controls all its configurations
- Home Manager integration remains automatic when niri module enabled
- No changes needed to host configurations
- Consistent with how other desktop modules handle per-user config

**Alternatives Considered**:
1. **Expose separate home-manager module output**
   - Pros: Cleaner separation, explicit opt-in
   - Cons: Requires hosts to import two modules, breaks existing pattern, more complex

2. **Keep current sharedModules pattern** ✅
   - Pros: Automatic, no host changes needed, encapsulated
   - Cons: Slightly less flexible (but flexibility not needed)

3. **Move home-manager config to main nixos module**
   - Pros: Simpler module structure
   - Cons: Violates separation of system/user concerns, harder to debug

**Implementation Notes**:
- default.nix will continue to check for home-manager availability
- Uses `homeManagerLoaded = builtins.hasAttr "home-manager" options;`
- Only injects sharedModules if home-manager present
- All 4 files (binds.nix, rules.nix, settings.nix, shell.nix) referenced with relative paths

---

## Research Area 3: Dependency Input Management

### Decision: Move All Niri-Related Inputs to Niri Flake

**Chosen**: Niri flake owns niri-flake, dankMaterialShell, dgop, dms-cli inputs

**Rationale**:
- Follows dependency encapsulation principle
- Main flake doesn't need to know about niri's upstream dependencies
- Enables independent version management
- Reduces main flake complexity
- Aligns with "why" of creating separate flake

**Alternatives Considered**:
1. **Keep niri-flake input in main flake**
   - Pros: Simpler migration (less to change)
   - Cons: Defeats purpose of independence, still coupled

2. **Move all niri deps to niri flake** ✅
   - Pros: True independence, cleaner main flake, proper encapsulation
   - Cons: Slightly more complex niri flake.nix

3. **Hybrid: niri-flake in main, shells in niri**
   - Pros: Some separation
   - Cons: Confusing split of responsibilities, partial solution

**Input Configuration**:

Main flake.nix (after):
```nix
inputs = {
  niri = {
    url = "path:./flakes/niri";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # Remove: niri-flake, dankMaterialShell, dgop, dms-cli
};
```

Niri flake.nix:
```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  niri-flake = {
    url = "github:sodiboo/niri-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  dgop = {
    url = "github:AvengeMedia/dgop";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  dms-cli = {
    url = "github:AvengeMedia/danklinux";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  dankMaterialShell = {
    url = "github:AvengeMedia/DankMaterialShell";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.dgop.follows = "dgop";
    inputs.dms-cli.follows = "dms-cli";
  };
};
```

---

## Research Area 4: Module Option Preservation

### Decision: No Changes to Module Options Structure

**Chosen**: Keep all existing options exactly as-is

**Rationale**:
- FR-009 explicitly requires preserving all module options
- Options interface is public API for hosts
- Changing options would break existing host configurations
- Options are already well-designed with proper fallbacks

**Module Options to Preserve**:
- `modules.desktop.niri.enable`
- `modules.desktop.niri.terminal`
- `modules.desktop.niri.browser`
- `modules.desktop.niri.editor`
- `modules.desktop.niri.fileManager`
- `modules.desktop.niri.passwordManager`

**Implementation Notes**:
- Option paths remain unchanged: `config.modules.desktop.niri.*`
- Fallback pattern preserved: `cfg.option -> defaults.option -> null`
- All descriptions and types stay identical
- No host configuration updates needed

---

## Research Area 5: Testing and Validation Strategy

### Decision: Multi-Stage Testing Approach

**Chosen**: Build verification → Integration testing → Manual validation

**Rationale**:
- Phased approach catches issues early
- Each stage validates different aspects
- Follows SC-001 through SC-006 from specification
- Matches existing nixos-rebuild workflow

**Testing Stages**:

1. **Flake Evaluation** (catches Nix syntax errors)
   ```bash
   nix flake check ./flakes/niri
   nix flake show ./flakes/niri
   ```

2. **Independent Build** (validates flake completeness)
   ```bash
   nix build ./flakes/niri
   ```

3. **Integration Build** (validates main flake integration)
   ```bash
   nixos-rebuild build --flake .#asus-zephyrus-gu603
   ```

4. **System Switch** (validates runtime functionality)
   ```bash
   nixos-rebuild switch --flake .#asus-zephyrus-gu603
   ```

5. **Manual Validation** (validates user-facing functionality)
   - Test all keybindings (Mod+Return, Mod+B, etc.)
   - Verify window rules apply correctly
   - Check DankMaterialShell loads properly
   - Verify spawn-at-startup services launch

6. **Update Independence** (validates flake isolation)
   ```bash
   cd flakes/niri
   nix flake update
   # Verify main flake.lock unchanged
   ```

**Success Criteria Mapping**:
- SC-001: Stage 2
- SC-002: Stage 4
- SC-003: Stage 5
- SC-004: Stage 6
- SC-005: Can verify with `nix build --rebuild`
- SC-006: Visual comparison of directory structures

---

## Research Area 6: Migration Path and Rollback

### Decision: Feature Branch with Atomic Commit

**Chosen**: Complete migration in single commit on feature branch, test before merge

**Rationale**:
- Git atomicity ensures all-or-nothing migration
- Feature branch enables testing without affecting main
- Single commit makes rollback trivial if issues found
- Follows existing git workflow for features

**Migration Steps**:
1. Create flakes/niri/ directory structure
2. Copy module files to new location
3. Create flake.nix in flakes/niri/
4. Update main flake.nix inputs
5. Update host imports (if needed)
6. Remove old modules/nixos/desktop/niri/
7. Run all test stages
8. Commit only if all tests pass

**Rollback Strategy**:
- If issues found post-merge: `git revert <commit-hash>`
- If issues during testing: abandon branch, restart with fixes
- NixOS built-in rollback: `nixos-rebuild switch --rollback`

---

## Summary of Key Decisions

| Area | Decision | Primary Benefit |
|------|----------|----------------|
| Flake Structure | Simple structure without flake-parts | Simplicity and clarity |
| Home Manager | Preserve sharedModules pattern | Zero host changes needed |
| Dependencies | Move all niri deps to niri flake | True independence |
| Module Options | No changes to options API | Backward compatibility |
| Testing | Multi-stage validation | Comprehensive verification |
| Migration | Atomic commit on feature branch | Safe, reversible process |

---

## Open Questions: None

All technical unknowns resolved. Ready to proceed to Phase 1 (Design).
