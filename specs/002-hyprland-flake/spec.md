# Feature Specification: Extract Hyprland Desktop Configuration to Separate Flake

**Feature Branch**: `002-hyprland-flake`
**Created**: 2025-11-10
**Status**: Draft
**Input**: User description: "Move the hyprland desktop configuration to a separate flake in the flakes directories along with the required references and inputs"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Isolated Hyprland Configuration Management (Priority: P1)

As a system administrator, I want the Hyprland desktop environment configuration to be managed as a standalone flake so that I can update, test, and version Hyprland-related components independently from the main NixOS configuration.

**Why this priority**: This is the core requirement that enables independent management and forms the foundation for all other benefits. Without this, version conflicts and testing complexity remain.

**Independent Test**: Can be fully tested by building the flake independently (`nix build ./flakes/hyprland`) and verifying it integrates with the main configuration without evaluation errors.

**Acceptance Scenarios**:

1. **Given** the hyprland configuration exists in modules/nixos/desktop/hyprland, **When** I extract it to flakes/hyprland/, **Then** the main NixOS configuration can consume it via path input and build successfully
2. **Given** the hyprland flake is created, **When** I run `nix flake check ./flakes/hyprland`, **Then** it evaluates without errors and shows nixosModules output
3. **Given** the hyprland flake integration is complete, **When** I build a host configuration that uses hyprland, **Then** all hyprland functionality works identically to before

---

### User Story 2 - Version Independence for Hyprland Ecosystem (Priority: P2)

As a system administrator, I want to update Hyprland and its ecosystem (plugins, waybar, hypridle, etc.) independently from the main system flake so that I can test new versions without risking system-wide dependency conflicts.

**Why this priority**: This provides the key operational benefit of independent updates, reducing risk and enabling faster iteration on Hyprland-specific features.

**Independent Test**: Can be tested by running `cd flakes/hyprland && nix flake update` and verifying the main flake.lock remains unchanged.

**Acceptance Scenarios**:

1. **Given** the hyprland flake exists with its own flake.lock, **When** I update dependencies in flakes/hyprland/, **Then** the main system flake.lock remains unchanged
2. **Given** I update hyprland ecosystem components, **When** I rebuild the system, **Then** only hyprland-related changes are applied without affecting other desktop environments

---

### User Story 3 - Reusable Hyprland Modules (Priority: P3)

As a NixOS user, I want to use the hyprland flake configuration in my own or other NixOS configurations so that I can benefit from tested hyprland setups without duplicating configuration code.

**Why this priority**: This enables community sharing and reuse, extending the value beyond the immediate configuration management needs.

**Independent Test**: Can be tested by consuming the flake from another NixOS configuration via standard flake inputs and verifying the hyprland environment works correctly.

**Acceptance Scenarios**:

1. **Given** the hyprland flake is properly structured, **When** another NixOS configuration references it as a flake input, **Then** the hyprland module can be imported and used successfully
2. **Given** the flake documentation exists, **When** external users follow the usage instructions, **Then** they can integrate hyprland configuration into their systems

---

### Edge Cases

- What happens when the hyprland flake has dependency conflicts with the main flake's inputs?
- How does the system handle when hyprland ecosystem components have breaking changes between versions?
- What occurs if the main flake's nixpkgs version is incompatible with hyprland flake requirements?
- How should the configuration handle when hyprland plugins require specific hyprland versions?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create a standalone flake in flakes/hyprland/ that contains all hyprland configuration modules
- **FR-002**: System MUST move all hyprland-related inputs (hyprland, waybar, pyprland, hyprland-contrib, hyprland-plugins, hyprpanel, hypridle, hyprpaper, hyprspace, hyprsplit, hyprchroma) from main flake to hyprland flake
- **FR-003**: System MUST preserve the complete hyprland module structure including config/, components/, and all subdirectories
- **FR-004**: System MUST maintain all module options (enable, package, portalPackage, gnomeCompatibility, hyprVariables, globalVariables, extraGlobalVariables) with identical behavior
- **FR-005**: System MUST preserve the preference fallback patterns for application defaults in hyprland keybindings
- **FR-006**: System MUST expose nixosModules.default output from the hyprland flake for consumption by the main configuration
- **FR-007**: System MUST update main flake.nix to reference hyprland flake via local path input instead of individual component inputs
- **FR-008**: System MUST ensure all hyprland ecosystem components (waybar, rofi, swaync, wlogout, workspaces, plugins) remain functional after migration
- **FR-009**: System MUST maintain home-manager integration with hyprland configuration modules
- **FR-010**: System MUST preserve all environment variables, systemd services, and XDG portal configuration

### Key Entities

- **Hyprland Flake**: Standalone flake containing complete hyprland ecosystem configuration with inputs, outputs, and module structure
- **Main Configuration Module**: Updated reference in modules/nixos/default.nix that imports from hyprland flake instead of local modules
- **Component Modules**: Modular configuration files for waybar, rofi, swaync, hypridle, hyprlock, workspaces, and plugins
- **Configuration Modules**: Core hyprland config files for binds, rules, settings, environment variables, and plugins
- **Home Manager Integration**: Shared modules that extend hyprland configuration to per-user home-manager contexts

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Hyprland flake builds independently with `nix build ./flakes/hyprland` completing without errors
- **SC-002**: System configuration builds successfully with `nixos-rebuild build` using the new hyprland flake integration
- **SC-003**: All hyprland functionality works identically to before migration when tested in a live hyprland session
- **SC-004**: Hyprland flake updates can be performed with `cd flakes/hyprland && nix flake update` without modifying main flake.lock
- **SC-005**: System rebuilds complete in similar time as before (within 10% performance variation)
- **SC-006**: Hyprland flake structure matches the established pattern from flakes/neovim/ for consistency
