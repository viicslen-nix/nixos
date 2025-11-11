# Implementation Plan: Extract Niri Desktop Configuration to Separate Flake

**Branch**: `001-niri-flake` | **Date**: 2025-11-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-niri-flake/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Extract the niri desktop environment configuration from `modules/nixos/desktop/niri/` into a standalone flake at `flakes/niri/` to enable independent versioning, testing, and updates. The flake will expose NixOS modules that can be consumed by the main configuration, following the same pattern as the existing `flakes/neovim/` flake. This supports the constitution's principles of modular configuration design and flake-based reproducibility while maintaining all existing functionality including keybinds, rules, settings, and home-manager integration.

## Technical Context

**Language/Version**: Nix 2.18+ with flakes enabled
**Primary Dependencies**:
- nixpkgs (nixos-unstable channel)
- niri-flake (github:sodiboo/niri-flake) - upstream niri compositor module
- home-manager - for per-user niri configuration
- dankMaterialShell - niri shell/panel implementation
- dgop - dependency of dankMaterialShell
- dms-cli - dependency of dankMaterialShell

**Storage**: Configuration files (.nix) stored in git, flake.lock for dependency pinning
**Testing**:
- `nix flake check` - Nix evaluation checks
- `nix build ./flakes/niri` - Build verification
- `nixos-rebuild build --flake .#<hostname>` - Integration testing
- Manual testing of desktop environment functionality

**Target Platform**: NixOS on x86_64-linux (desktop/laptop hosts)
**Project Type**: NixOS configuration flake (declarative system configuration)
**Performance Goals**:
- Flake evaluation time < 5 seconds
- Independent flake updates < 30 seconds
- No performance regression in niri desktop environment

**Constraints**:
- Must maintain backward compatibility with existing host configurations
- Must preserve all existing keybindings and window rules
- Cannot break home-manager integration
- Must follow existing flake pattern from flakes/neovim/

**Scale/Scope**:
- 5 module files (default.nix, binds.nix, rules.nix, settings.nix, shell.nix)
- ~500 lines of Nix configuration
- Multiple host configurations (primarily asus-zephyrus-gu603)
- Integration with 3 external flake inputs (niri, dankMaterialShell ecosystem)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Modular Configuration Design ✅ PASS

**Requirement**: Configurations organized as reusable modules with clear separation of concerns

**Assessment**: This feature ENHANCES modularity by:
- Extracting niri configuration into standalone flake
- Maintaining clear separation (niri modules stay isolated)
- Enabling independent reuse across configurations
- Following existing pattern from flakes/neovim/

**Action**: No violations. Proceed.

---

### II. Declarative System State Management ✅ PASS

**Requirement**: All system state declared in Nix expressions

**Assessment**: Migration is purely declarative:
- Moving .nix files between directories
- Updating flake inputs (declarative references)
- No imperative state changes
- All configuration remains in Nix expressions

**Action**: No violations. Proceed.

---

### III. Multi-Host Compatibility ✅ PASS

**Requirement**: Configurations support deployment across diverse hardware

**Assessment**:
- Flake consumed via local path input (works on all hosts)
- Host-specific niri configs remain in hosts/<hostname>/
- No hardcoded assumptions introduced
- Existing multi-host support preserved

**Action**: No violations. Proceed.

---

### IV. Flake-Based Reproducibility ✅ PASS

**Requirement**: All dependencies managed through Nix flakes

**Assessment**: This feature STRENGTHENS flake-based reproducibility by:
- Creating dedicated flake.lock for niri dependencies
- Enabling independent version pinning
- Moving niri-flake input from main to niri subflake
- Maintaining hermetic builds

**Action**: No violations. Proceed.

---

### V. Preference Fallback Patterns ✅ PASS

**Requirement**: Configuration options support flexible preference resolution

**Assessment**:
- Existing fallback pattern in binds.nix must be preserved (FR-006)
- Pattern: `cfg.terminal -> defaults.terminal -> null`
- Already documented in current implementation
- No changes to preference resolution logic

**Action**: No violations. Document preservation in tasks.

---

### VI. Documentation & Maintainability ✅ PASS

**Requirement**: All modules and non-trivial configurations documented

**Assessment**:
- Module options already documented with descriptions
- Flake structure will follow neovim pattern (well-documented)
- Migration process documented in this plan
- Module relationships clear in flake outputs

**Action**: Ensure flake.nix includes descriptive comments for outputs.

---

### VII. Code Clarity Over Cleverness ✅ PASS

**Requirement**: Nix expressions prioritize readability

**Assessment**:
- No clever tricks required for this migration
- Simple file move + flake structure creation
- Clear flake outputs with named attributes
- Following established patterns

**Action**: No violations. Proceed.

---

### VIII. Consistent User Interface Patterns ✅ PASS

**Requirement**: Desktop environments maintain consistency

**Assessment**:
- No changes to keybindings (FR-005)
- No changes to window rules or settings
- UI patterns preserved identically
- Only structural reorganization

**Action**: Verify keybindings work identically post-migration (SC-003).

---

### Summary

**Status**: ✅ ALL GATES PASS

No constitution violations. This feature aligns with and enhances multiple principles:
- Strengthens Principle I (Modular Configuration Design)
- Strengthens Principle IV (Flake-Based Reproducibility)
- Maintains all other principles without violations

**Clearance**: Proceed to Phase 0 (Research)

## Project Structure

### Documentation (this feature)

```text
specs/001-niri-flake/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output - Module structure documentation
├── quickstart.md        # Phase 1 output - Testing and validation guide
├── contracts/           # Phase 1 output - Flake output schema
└── checklists/
    └── requirements.md  # Specification quality checklist (already created)
```

### Source Code (repository root)

```text
# New flake structure (to be created)
flakes/niri/
├── flake.nix           # Main flake definition with inputs and outputs
├── flake.lock          # Locked dependency versions
├── default.nix         # Main niri module with options and enable logic
├── binds.nix           # Keybinding configurations with preference fallbacks
├── rules.nix           # Window rules and layer rules
├── settings.nix        # General niri settings and spawn-at-startup
└── shell.nix           # DankMaterialShell integration

# Existing structure (to be modified)
flake.nix               # Update: Add niri flake as local path input
modules/nixos/desktop/
├── niri/               # TO BE REMOVED after migration
│   ├── default.nix
│   ├── binds.nix
│   ├── rules.nix
│   ├── settings.nix
│   └── shell.nix
└── ...

hosts/                  # Update module import paths
├── asus-zephyrus-gu603/
│   └── default.nix     # Update to import from niri flake instead
└── ...
```

**Structure Decision**: Following the NixOS configuration flake pattern established by `flakes/neovim/`. The niri flake will:

1. **Be self-contained**: All 5 module files move to `flakes/niri/` directory
2. **Expose NixOS modules**: Via `nixosModules.default` output
3. **Manage own dependencies**: niri-flake, dankMaterialShell inputs in local flake.nix
4. **Be consumed locally**: Main flake.nix adds `niri.url = "path:./flakes/niri"`
5. **Support independent updates**: Own flake.lock enables isolated dependency management

This structure aligns with Constitution Principle I (Modular Configuration Design) and follows existing repository patterns.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution violations detected. All principles either maintained or enhanced by this feature.

This section intentionally left minimal as no complexity justification is required.
