# Feature Specification: Extract Niri Desktop Configuration to Separate Flake

**Feature Branch**: `001-niri-flake`
**Created**: 2025-11-05
**Status**: Draft
**Input**: User description: "move the niri desktop configuration to a separate flake in the flakes directories along with the required references"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Isolated Niri Configuration Management (Priority: P1)

System administrators can manage the niri desktop environment configuration independently from the main NixOS configuration through a dedicated flake in `flakes/niri/`.

**Why this priority**: Enables independent versioning, testing, and updates of the niri desktop environment without affecting the main system configuration. This is the core functionality that delivers immediate value.

**Independent Test**: Can be fully tested by building the niri flake independently (`nix build ./flakes/niri`) and verifying it produces valid niri configuration outputs without requiring the main NixOS flake.

**Acceptance Scenarios**:

1. **Given** the niri flake exists in `flakes/niri/`, **When** a system administrator runs `nix flake show ./flakes/niri`, **Then** the flake outputs are displayed showing packages and modules
2. **Given** the niri flake is configured, **When** the main NixOS configuration imports it, **Then** the niri desktop environment functions identically to the previous integrated configuration
3. **Given** changes are made to the niri flake, **When** rebuilding the system, **Then** only the niri-related configuration is rebuilt without affecting unrelated modules

---

### User Story 2 - Version Independence (Priority: P2)

System administrators can update the niri configuration flake independently by updating its flake.lock without triggering updates to the main system flake dependencies.

**Why this priority**: Provides flexibility in managing desktop environment updates separately from system-level updates, reducing risk and enabling faster iteration on desktop configurations.

**Independent Test**: Can be tested by running `nix flake update` within `flakes/niri/` directory and verifying that the main `/etc/nixos/flake.lock` remains unchanged.

**Acceptance Scenarios**:

1. **Given** the niri flake has its own `flake.lock`, **When** running `nix flake update` in `flakes/niri/`, **Then** only the niri flake dependencies are updated
2. **Given** a new version of niri-flake upstream is available, **When** updating the niri flake input, **Then** the update is isolated to the niri subdirectory

---

### User Story 3 - Reusable Niri Modules (Priority: P3)

The niri flake can be consumed by other NixOS configurations or shared across multiple hosts by referencing the local flake path or publishing it separately.

**Why this priority**: Enables code reuse and sharing of niri configurations, though this is a future enhancement rather than immediate requirement.

**Independent Test**: Can be tested by importing the niri flake into a different NixOS configuration using a flake input and verifying the niri desktop environment is available.

**Acceptance Scenarios**:

1. **Given** another NixOS configuration, **When** adding the niri flake as an input, **Then** the niri modules and packages are available for import
2. **Given** the niri flake is referenced from multiple hosts, **When** each host enables the niri module, **Then** each receives the same consistent niri configuration

---

### Edge Cases

- What happens when the niri flake input reference is removed from the main flake while hosts still try to import niri modules?
- How does the system handle version mismatches between the niri flake's nixpkgs input and the main flake's nixpkgs?
- What if the niri upstream flake (sodiboo/niri-flake) is temporarily unavailable when updating?
- How are circular dependencies prevented when the niri flake might want to reference main flake utilities?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create a new flake structure in `flakes/niri/` with its own `flake.nix` and `flake.lock`
- **FR-002**: System MUST move all niri-related modules from `modules/nixos/desktop/niri/` to `flakes/niri/` maintaining their relative structure
- **FR-003**: System MUST expose niri modules through the flake outputs as NixOS modules consumable by the main configuration
- **FR-004**: System MUST update the main `flake.nix` to reference the local niri flake as an input (e.g., `path:./flakes/niri`)
- **FR-005**: System MUST maintain all existing niri functionality including keybinds, rules, settings, and shell configuration
- **FR-006**: System MUST preserve the preference fallback pattern for terminal, browser, editor, fileManager, and passwordManager options
- **FR-007**: System MUST maintain the home-manager shared modules integration for per-user niri configuration
- **FR-008**: System MUST reference the upstream niri-flake (`github:sodiboo/niri-flake`) as an input to the new niri flake, not the main flake
- **FR-009**: System MUST preserve all module options and their descriptions from the original configuration
- **FR-010**: System MUST maintain compatibility with all existing host configurations that use niri

### Key Entities

- **Niri Flake**: Standalone flake containing niri desktop configuration, located at `flakes/niri/`
  - Contains: `flake.nix`, `flake.lock`, module files (default.nix, binds.nix, rules.nix, settings.nix, shell.nix)
  - Inputs: nixpkgs, niri upstream flake, potentially home-manager
  - Outputs: NixOS modules, packages (if any)

- **Niri Module Files**: Configuration files that define niri behavior
  - `default.nix`: Main module with options and enable logic
  - `binds.nix`: Keybinding configurations with preference fallbacks
  - `rules.nix`: Window rules and behaviors
  - `settings.nix`: General niri settings
  - `shell.nix`: Shell-related niri configuration

- **Main Flake Reference**: Input definition in the root `flake.nix` pointing to the local niri flake
  - Type: path input
  - Location: `./flakes/niri`

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The niri flake can be built independently with `nix build ./flakes/niri` without errors
- **SC-002**: System rebuild with `nixos-rebuild switch --flake .#<hostname>` succeeds for all hosts that previously used niri
- **SC-003**: All existing niri keybindings, window rules, and settings function identically after the migration
- **SC-004**: The niri flake can be updated independently by running `nix flake update` in `flakes/niri/` without affecting the main flake.lock
- **SC-005**: Configuration changes to niri modules trigger rebuilds only for niri-related components, not unrelated system modules
- **SC-006**: The niri flake structure follows the same patterns as the existing `flakes/neovim/` flake for consistency

## Assumptions

- The niri flake will use the same nixpkgs version as the main flake initially, with the option to diverge later
- All niri-related configuration currently resides in `modules/nixos/desktop/niri/` with no external dependencies beyond what's already imported
- The existing home-manager integration pattern will be preserved within the niri flake
- The flake will be consumed locally via path input initially, with the option to publish separately in the future
- The upstream niri-flake input provides the base niri NixOS module that our configuration extends
