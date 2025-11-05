<!--
  Sync Impact Report
  ==================
  Version change: 0.0.0 → 1.0.0
  Rationale: Initial constitution creation for NixOS configuration management project

  New Principles:
  - I. Modular Configuration Design
  - II. Declarative System State Management
  - III. Multi-Host Compatibility
  - IV. Flake-Based Reproducibility
  - V. Preference Fallback Patterns
  - VI. Documentation & Maintainability
  - VII. Code Clarity Over Cleverness
  - VIII. Consistent User Interface Patterns

  Templates Status:
  ✅ plan-template.md - Constitution Check section already generic and adaptable
  ✅ spec-template.md - Requirements and success criteria align with declarative principles
  ✅ tasks-template.md - Task organization supports modular development approach

  Follow-up TODOs: None - all placeholders filled
-->

# NixOS Configuration Constitution

## Core Principles

### I. Modular Configuration Design

All NixOS and Home Manager configurations MUST be organized as reusable modules with clear separation of concerns:

- System-level concerns belong in `modules/nixos/` (hardware, desktop environments, system programs)
- User-level concerns belong in `modules/home-manager/` (user programs, dotfiles, user functionality)
- Host-specific configurations import and enable modules without duplicating logic
- Each module MUST have a single, well-defined purpose (e.g., "bluetooth support", "git configuration")
- Modules MUST expose options for customization rather than hardcoding values
- Cross-cutting functionality (e.g., theming, defaults) MUST be shared through dedicated modules

**Rationale**: Modularity enables reuse across multiple hosts, reduces duplication, improves maintainability, and allows incremental system changes without affecting unrelated components.

### II. Declarative System State Management

All system state MUST be declared in Nix expressions with no imperative modifications:

- System configuration declared in `.nix` files, not manual `systemctl` or filesystem edits
- User environment declared in Home Manager modules, not manual dotfile symlinks
- Package installations declared in configuration, not ad-hoc `nix-env` commands
- Services configured declaratively with NixOS options, not by editing service files
- Secrets managed through agenix (encrypted `.age` files), referenced declaratively in `secrets.nix`
- State persistence managed explicitly through impermanence modules when using tmpfs root

**Rationale**: Declarative configuration ensures reproducibility, enables atomic rollbacks, provides clear audit trails, and prevents configuration drift across rebuilds.

### III. Multi-Host Compatibility

Configurations MUST support deployment across diverse hardware and environments:

- Base functionality shared through common modules (imported in `modules/nixos/all.nix` or `modules/home-manager/all.nix`)
- Host-specific overrides isolated to `hosts/<hostname>/` directories
- Hardware detection and configuration abstracted through `hardware.nix` files
- Desktop environment choices configurable per-host without affecting shared modules
- Development environments MUST work consistently across physical machines, WSL, and remote systems
- Conditional logic MUST check for feature availability rather than hardcoding assumptions

**Rationale**: Multi-host compatibility maximizes configuration reuse, reduces maintenance burden, and ensures consistent experience across all user environments.

### IV. Flake-Based Reproducibility

All dependencies and system inputs MUST be managed through Nix flakes:

- `flake.nix` declares all external dependencies (nixpkgs, home-manager, etc.)
- `flake.lock` pins exact versions of all inputs for reproducible builds
- Updates to dependencies performed explicitly via `nix flake update` or `just update`
- Custom packages defined in `packages/` with clear dependency declarations
- Overlays in `overlays/` MUST NOT break reproducibility by fetching unpinned sources
- Development shells in `dev-shells/` declare exact tool versions

**Rationale**: Flakes provide hermetic builds, enable rollback to previous system generations, and ensure "it works on my machine" applies to all machines.

### V. Preference Fallback Patterns

Configuration options MUST support flexible preference resolution:

- Module-specific options take highest priority (e.g., `cfg.terminal`)
- Fall back to functionality defaults (e.g., `config.modules.functionality.defaults.terminal`)
- Fall back to `null` if neither is set, with appropriate error handling
- Pattern: `if cfg.option != null then cfg.option else defaults.option or null`
- Modules MUST handle `null` gracefully (skip bindings, show warnings, provide safe defaults)
- Document the preference hierarchy in module comments

**Rationale**: Fallback patterns enable sensible defaults while allowing per-module overrides, reduce configuration boilerplate, and make configurations self-documenting.

### VI. Documentation & Maintainability

All modules and non-trivial configurations MUST be documented:

- Module options documented with `description`, `type`, and `default` attributes
- Complex logic explained with inline comments
- Inter-module dependencies noted in module documentation
- Breaking changes documented in commit messages
- Host-specific quirks documented in respective `hosts/<hostname>/README.md` or comments
- Non-obvious hardware configurations annotated with hardware model references

**Rationale**: Documentation reduces cognitive load for future modifications, helps onboard new contributors, and prevents accidental breakage of undocumented dependencies.

### VII. Code Clarity Over Cleverness

Nix expressions MUST prioritize readability and explicitness:

- Prefer explicit attribute sets over implicit argument destructuring when it aids clarity
- Use `let...in` bindings to name intermediate values descriptively
- Avoid deeply nested conditionals; extract to named variables
- Use `lib` functions (e.g., `optional`, `optionalAttrs`, `mkIf`) idiomatically
- Split large modules into logical sub-modules rather than creating monolithic files
- Avoid Nix language tricks that sacrifice readability for brevity

**Rationale**: Clear code is maintainable code. NixOS configurations are long-lived and frequently modified; optimizing for human comprehension reduces errors and speeds iteration.

### VIII. Consistent User Interface Patterns

Desktop environments and user-facing configurations MUST maintain consistency:

- Keybindings follow shared conventions across desktop environments (e.g., Mod+Return for terminal)
- Common operations (launcher, browser, file manager) bound consistently
- Visual themes coordinated through Stylix or equivalent system-wide theming
- Application launchers and status bars configured with similar information density
- Accessibility settings (font sizes, contrast) consistent across hosts with similar form factors
- Modifier key conventions (Mod vs Ctrl vs Alt) documented and applied uniformly

**Rationale**: Consistent UI patterns reduce cognitive load when switching between hosts or desktop environments, improve muscle memory, and create a cohesive user experience.

## Configuration Management Workflow

### Change Process

1. **Planning**: Identify affected modules and hosts before making changes
2. **Isolation**: Make changes in feature branches when experimenting with major configuration shifts
3. **Testing**: Build configuration with `nixos-rebuild build --flake .#<hostname>` before switching
4. **Validation**: Use `just diff` or `diff.sh` to review changes before applying
5. **Application**: Apply with `nixos-rebuild switch --flake .#<hostname>` or `just nix-upgrade switch`
6. **Rollback**: If issues arise, rollback with `nixos-rebuild switch --rollback`

### Module Development Standards

- New modules MUST follow template structure in `templates/nixos-module.nix.tmpl` or `templates/hm-module.nix.tmpl`
- Modules MUST define enable option: `config.modules.<category>.<name>.enable`
- Module imports MUST be added to appropriate `all.nix` aggregation file
- Modules MUST use `mkIf cfg.enable` to conditionally apply configuration
- Module options MUST use appropriate `lib.mkOption` with types from `lib.types`

### Quality Gates

Before committing configuration changes, verify:

- [ ] Configuration builds successfully for affected hosts
- [ ] No Nix evaluation errors or warnings
- [ ] Changed modules documented with option descriptions
- [ ] Host-specific changes isolated to `hosts/<hostname>/` directories
- [ ] Shared functionality extracted to reusable modules
- [ ] Flake lock updated if dependencies changed
- [ ] Secrets properly encrypted if added to `secrets/`

## Governance

This constitution establishes the architectural and operational principles for this NixOS configuration repository. All configuration changes, module additions, and refactoring efforts MUST align with these principles.

### Amendment Process

1. Propose amendment via issue or discussion with rationale
2. Document impact on existing configurations
3. Update constitution with version bump per semantic versioning
4. Update affected templates and documentation
5. Create migration guide if breaking changes required

### Versioning Policy

Constitution version follows semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Principle removed, redefined, or fundamentally restructured (breaks existing patterns)
- **MINOR**: New principle added or existing principle materially expanded
- **PATCH**: Clarifications, wording improvements, typo fixes

### Compliance

- All pull requests and configuration changes MUST be reviewed against these principles
- Violations MUST be justified in commit messages or pull request descriptions
- Complex configurations that appear to violate principles MUST document "why simpler alternatives were insufficient"
- This document supersedes ad-hoc practices and verbal conventions

**Version**: 1.0.0 | **Ratified**: 2025-11-05 | **Last Amended**: 2025-11-05
