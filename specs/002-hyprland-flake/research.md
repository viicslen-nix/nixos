# Research: Extract Hyprland Desktop Configuration to Separate Flake

**Feature**: 002-hyprland-flake
**Date**: 2025-11-10

## Overview

This document captures research findings and technical decisions for extracting the Hyprland desktop environment configuration into a standalone flake. The goal is to enable independent versioning and updates while maintaining all existing functionality.

---

## Research Area 1: Flake Structure and Architecture

**Question**: What flake structure should be used to organize the 30+ Hyprland configuration modules?

**Decision**: Simple flake structure with direct module imports (not flake-parts)

**Rationale**:
- Following established pattern from `flakes/neovim/` for consistency
- Simple structure is easier to understand and maintain
- Direct module imports preserve existing inter-module relationships
- Avoids complexity of flake-parts for configuration modules
- Enables clear nixosModules.default output pattern

**Alternatives considered**:
- flake-parts based structure - rejected due to added complexity for configuration modules
- Monolithic single module file - rejected due to loss of modularity
- Per-component sub-flakes - rejected due to management overhead

---

## Research Area 2: Home Manager Integration Patterns

**Question**: How should home-manager sharedModules be preserved when moving to flake?

**Decision**: Preserve existing sharedModules pattern with relative imports

**Rationale**:
- Current home-manager integration works well with imports in default.nix
- Relative paths (./config, ./components) work within flake directory
- Maintains clear separation of NixOS vs home-manager configuration
- Allows per-component configuration flexibility
- Follows existing pattern from niri flake migration

**Alternatives considered**:
- Export separate homeManagerModules outputs - rejected due to complexity
- Inline all home-manager config - rejected due to loss of modularity
- Use absolute paths - rejected due to brittleness

---

## Research Area 3: Input Dependencies Management

**Question**: How should the 10 Hyprland ecosystem dependencies be managed in the flake?

**Decision**: Move all Hyprland-related inputs to hyprland flake with nixpkgs follows

**Rationale**:
- Isolates Hyprland ecosystem dependencies from main flake
- Enables independent updates of Hyprland without affecting other desktop environments
- Reduces dependency conflicts in main flake
- Clear ownership of related dependencies (all in one flake)
- Follows nixpkgs for consistency across ecosystem

**Alternatives considered**:
- Keep some inputs in main flake - rejected due to dependency coupling
- Separate flakes per component - rejected due to management complexity
- No follows constraints - rejected due to potential dependency conflicts

---

## Research Area 4: Module Options API Preservation

**Question**: Should the module API change during the migration to flake?

**Decision**: No changes to module options API - preserve identical behavior

**Rationale**:
- Maintains backward compatibility with existing host configurations
- Reduces migration risk and testing complexity
- Users expect identical functionality after structural changes
- Option descriptions and types already well-defined
- Focus on structure change, not API change

**Alternatives considered**:
- Simplify options during migration - rejected due to breaking changes
- Add new flake-specific options - rejected due to scope creep
- Rename options for consistency - rejected due to migration complexity

---

## Research Area 5: Testing and Validation Strategy

**Question**: What testing approach should be used to validate the migration?

**Decision**: Multi-stage testing approach with rollback capability

**Rationale**:
- Incremental validation reduces risk of breaking functional desktop
- Independent flake testing ensures flake structure is correct
- Integration testing validates main configuration consumption
- Manual functional testing ensures user experience preserved
- Rollback capability provides safety net for issues

**Alternatives considered**:
- Automated testing only - rejected due to complexity of desktop testing
- Single-stage validation - rejected due to high risk of issues
- No rollback plan - rejected due to safety concerns

---

## Research Area 6: Migration Strategy

**Question**: Should the migration be atomic or incremental?

**Decision**: Atomic migration with complete flake creation and cutover

**Rationale**:
- Simpler to reason about and implement than incremental approach
- Follows pattern established by niri flake migration
- Easier to validate complete functionality in single step
- Reduces complexity of maintaining both old and new simultaneously
- Clear success/failure criteria

**Alternatives considered**:
- Incremental component migration - rejected due to inter-component dependencies
- Parallel maintenance - rejected due to maintenance burden
- Feature flagged migration - rejected due to added complexity

---

## Implementation Notes

### Key Dependencies to Migrate
Based on analysis of main flake.nix:
- hyprland (core compositor)
- waybar (status bar)
- pyprland (utilities)
- hyprland-contrib (additional tools)
- hyprland-plugins (compositor plugins)
- hyprpanel (alternative panel)
- hypridle (idle management)
- hyprpaper (wallpaper utility)
- hyprspace (workspace management)
- hyprsplit (window splitting)
- hyprchroma (color management)

### Module Structure Analysis
Current structure in modules/nixos/desktop/hyprland/:
- default.nix (main module with options)
- config/ (6 core configuration modules)
- components/ (20+ component modules)

### Integration Points
- Main flake inputs section
- modules/nixos/default.nix desktop exports
- modules/nixos/all.nix imports
- Host configurations that enable hyprland

---

## Risk Mitigation

### High Risk Items
1. **Complex module interdependencies** - Mitigated by preserving exact module structure
2. **Home manager integration breakage** - Mitigated by testing sharedModules pattern
3. **Plugin compatibility issues** - Mitigated by maintaining exact input versions initially

### Medium Risk Items  
1. **Performance regression** - Mitigated by benchmark testing
2. **Build failures** - Mitigated by staged validation approach
3. **Missing dependencies** - Mitigated by comprehensive input analysis

### Low Risk Items
1. **Configuration drift** - Mitigated by git-based atomic changes
2. **Documentation gaps** - Mitigated by following established patterns

---

**Research Complete**: All technical decisions documented and ready for Phase 1 design.