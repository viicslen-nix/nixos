# Implementation Plan: Extract Hyprland Desktop Configuration to Separate Flake

**Branch**: `002-hyprland-flake` | **Date**: 2025-11-10 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-hyprland-flake/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Extract the Hyprland desktop environment configuration from `modules/nixos/desktop/hyprland/` into a standalone flake at `flakes/hyprland/` to enable independent versioning, testing, and updates. The flake will expose NixOS modules that can be consumed by the main configuration, following the same pattern as the existing `flakes/neovim/` flake. This supports the constitution's principles of modular configuration design and flake-based reproducibility while maintaining all existing functionality including keybinds, rules, settings, and home-manager integration.

## Technical Context

**Language/Version**: Nix 2.18+ with flakes enabled
**Primary Dependencies**:
- nixpkgs (nixos-unstable channel)
- hyprland (github:hyprwm/Hyprland) - main wayland compositor
- home-manager - for per-user hyprland configuration
- waybar (github:Alexays/Waybar) - wayland status bar
- pyprland (github:hyprland-community/pyprland) - hyprland utilities
- hyprland-contrib (github:hyprwm/contrib) - additional tools
- hyprland-plugins (github:hyprwm/hyprland-plugins) - compositor plugins
- hyprpanel (github:Jas-SinghFSU/HyprPanel) - alternative panel
- hypridle (github:hyprwm/hypridle) - idle management
- hyprpaper (github:hyprwm/hyprpaper) - wallpaper utility
- hyprspace (github:KZDKM/Hyprspace) - workspace management
- hyprsplit (github:shezdy/hyprsplit) - window splitting
- hyprchroma (github:alexhulbert/Hyprchroma) - color management

**Storage**: Configuration files (.nix) stored in git, flake.lock for dependency pinning
**Testing**:
- `nix flake check` - Nix evaluation checks
- `nix build ./flakes/hyprland` - Build verification
- `nixos-rebuild build --flake .#<hostname>` - Integration testing
- Manual testing of desktop environment functionality

**Target Platform**: NixOS on x86_64-linux (desktop/laptop hosts)
**Project Type**: NixOS configuration flake (declarative system configuration)
**Performance Goals**:
- Flake evaluation time < 10 seconds
- Independent flake updates < 60 seconds
- No performance regression in hyprland desktop environment

**Constraints**:
- Must maintain backward compatibility with existing host configurations
- Must preserve all existing keybindings and window rules
- Cannot break home-manager integration
- Must follow existing flake pattern from flakes/neovim/
- Complex module structure (config/ and components/ subdirectories)

**Scale/Scope**:
- 30+ module files across config/ and components/ directories
- ~2000 lines of Nix configuration
- 10 external flake inputs to migrate
- Multiple host configurations (asus-zephyrus-gu603, home-desktop)
- Integration with 8+ component types (waybar, rofi, swaync, plugins, etc.)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Modular Configuration Design ✅ PASS

**Requirement**: All NixOS and Home Manager configurations MUST be organized as reusable modules with clear separation of concerns

**Assessment**: This feature ENHANCES modularity by:
- Extracting hyprland configuration into standalone flake with clear module boundaries
- Maintaining separation: system-level (NixOS modules) vs user-level (home-manager modules) concerns
- Enabling independent reuse across configurations
- Following existing flake pattern from flakes/neovim/
- Preserving single-purpose module design (desktop environment focus)

**Action**: No violations. Proceed.

---

### II. Declarative System State Management ✅ PASS

**Requirement**: All system state MUST be declared in Nix expressions with no imperative modifications

**Assessment**: Migration is purely declarative:
- Moving .nix files between directories (declarative file management)
- Updating flake inputs (declarative dependency references)
- No imperative state changes or manual configuration edits
- All hyprland configuration remains in Nix expressions
- Preserves declarative service and environment management

**Action**: No violations. Proceed.

---

### III. Multi-Host Compatibility ✅ PASS

**Requirement**: Configurations MUST support deployment across diverse hardware and environments

**Assessment**:
- Flake consumed via local path input (works on all hosts)
- Host-specific hyprland configs remain in hosts/<hostname>/
- No hardcoded hardware assumptions introduced
- Existing multi-host support preserved (desktop, laptop, WSL)
- Conditional logic for gnomeCompatibility maintained

**Action**: No violations. Proceed.

---

### IV. Flake-Based Reproducibility ✅ PASS

**Requirement**: All dependencies and system inputs MUST be managed through Nix flakes

**Assessment**: This feature STRENGTHENS flake-based reproducibility by:
- Creating dedicated flake.lock for hyprland ecosystem dependencies
- Enabling independent version pinning of hyprland components
- Moving 10 hyprland-related inputs from main to hyprland subflake
- Maintaining hermetic builds with locked versions
- Following flake-based dependency management patterns

**Action**: No violations. Proceed.

---

### V. Preference Fallback Patterns ✅ PASS

**Requirement**: Configuration options MUST support flexible preference resolution

**Assessment**:
- Existing preference patterns in hyprland keybinds must be preserved
- Pattern: module-specific → defaults → null maintained
- No changes to preference resolution logic in migration
- Option definitions preserved identically from current modules

**Action**: Ensure preference fallback patterns are preserved in migration tasks.

---

### VI. Documentation & Maintainability ✅ PASS

**Requirement**: All modules and non-trivial configurations MUST be documented

**Assessment**:
- Module options already documented with descriptions and types
- Complex hyprland integration already has inline comments
- Flake structure will follow neovim pattern (well-documented)
- Migration process documented in this plan
- Module relationships clear in flake outputs

**Action**: Ensure flake.nix includes descriptive comments for outputs and complex dependencies.

---

### VII. Code Clarity Over Cleverness ✅ PASS

**Requirement**: Nix expressions MUST prioritize readability and explicitness

**Assessment**:
- No clever tricks required for this migration
- Simple file move + flake structure creation
- Clear flake outputs with named attributes
- Following established patterns (reduces cognitive load)
- Explicit dependency management through flake inputs

**Action**: No violations. Proceed.

---

### VIII. Consistent User Interface Patterns ✅ PASS

**Requirement**: Desktop environments and user-facing configurations MUST maintain consistency

**Assessment**:
- No changes to keybindings (FR-005 preserves patterns)
- No changes to visual themes or UI consistency
- Hyprland-specific patterns preserved identically
- Integration with system-wide theming maintained
- Multi-desktop environment support unaffected

**Action**: Verify keybindings and UI patterns work identically post-migration.

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
specs/002-hyprland-flake/
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
flakes/hyprland/
├── flake.nix           # Main flake definition with inputs and outputs
├── flake.lock          # Locked dependency versions
├── default.nix         # Main hyprland module with options and enable logic
└── [30+ module files]  # Complete config/ and components/ directories

# Existing structure (to be modified)
flake.nix               # Update: Add hyprland flake as local path input
modules/nixos/desktop/
├── hyprland/           # TO BE REMOVED after migration
│   ├── default.nix
│   ├── config/         # 6 config modules (binds, env, rules, settings, plugins)
│   └── components/     # 20+ component modules (waybar, rofi, swaync, etc.)
└── ...

hosts/                  # Update module import paths
├── asus-zephyrus-gu603/
│   └── default.nix     # Update to import from hyprland flake instead
├── home-desktop/
│   └── default.nix     # Update to import from hyprland flake instead
└── ...
```

**Structure Decision**: Following the NixOS configuration flake pattern established by `flakes/neovim/`. The hyprland flake will:

1. **Be self-contained**: All 30+ module files move to `flakes/hyprland/` directory
2. **Expose NixOS modules**: Via `nixosModules.default` output
3. **Manage own dependencies**: 10 hyprland ecosystem inputs in local flake.nix
4. **Be consumed locally**: Main flake.nix adds `hyprland.url = "path:./flakes/hyprland"`
5. **Support independent updates**: Own flake.lock enables isolated dependency management

This structure aligns with Constitution Principle I (Modular Configuration Design) and follows existing repository patterns.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution violations detected. All principles either maintained or enhanced by this feature.

This section intentionally left minimal as no complexity justification is required.

---

## Phase 1: Design (COMPLETE)

**Duration**: Complete
**Deliverables**: ✅ All artifacts generated

### Completed Design Artifacts

#### 1. `data-model.md` ✅
**Purpose**: Module structure documentation
**Content**:
- Flake output schema with nixosModules.default
- Complete module hierarchy (30+ files mapped)
- Integration patterns (home-manager, systemd services)
- Data flow and dependency management
- Migration path mapping from current structure

#### 2. `contracts/flake-outputs.md` ✅
**Purpose**: Interface specification for flake consumption
**Content**:
- Required flake.nix output schema
- NixOS module interface contract (options + behavior)
- Consumption patterns for main flake integration
- Testing contracts with validation procedures
- Compatibility guarantees and versioning approach

#### 3. `quickstart.md` ✅
**Purpose**: Testing and validation procedures
**Content**:
- Pre-migration baseline testing procedures
- Progressive migration testing (3 phases)
- Post-migration functional validation
- Independent update testing approach
- Rollback procedures and troubleshooting guide
- Success criteria with validation commands

### Design Decisions Summary

**Architecture**: Simple flake structure following flakes/neovim/ pattern
- Direct module imports (not flake-parts)
- Single nixosModules.default output
- Local path consumption with nixpkgs follows

**Migration Strategy**: Atomic migration with complete cutover
- Preserve exact module API and functionality
- Maintain home-manager sharedModules pattern
- Move all 10 hyprland inputs to dedicated flake
- Support rollback via git reset

**Testing Approach**: Multi-stage validation with safety nets
- Baseline establishment → progressive testing → final validation
- Build testing + functional testing + performance validation
- Independent update capability testing
- Documented troubleshooting and recovery procedures

**Ready for**: Phase 2 (Task Generation)

---

## Phase 2: Task Generation (COMPLETE)

**Duration**: Complete
**Deliverable**: `tasks.md` ✅

**Objective**: Generate comprehensive implementation tasks broken down by user story and execution phase.

**Output**: Created comprehensive task breakdown with 97 tasks organized across:
- **Phase 1-2**: Setup and foundational infrastructure (9 tasks)
- **Phase 3**: User Story 1 - Isolated Management (61 tasks) - MVP priority
- **Phase 4**: User Story 2 - Version Independence (9 tasks)
- **Phase 5**: User Story 3 - Reusable Modules (9 tasks)
- **Phase 6**: Polish and validation (9 tasks)

**Key Features**:
- **Parallel execution**: 35+ tasks identified for parallel execution to optimize implementation time
- **Progressive validation**: Multi-stage testing approach with checkpoints after each user story
- **Comprehensive scope**: Covers 30+ module files, 10 input dependencies, multiple host configurations
- **Safety measures**: Includes functional testing, rollback procedures, and validation at each step
- **MVP focus**: User Story 1 (61 tasks) contains all essential functionality for standalone hyprland flake

**Ready for**: Implementation execution following task breakdown
