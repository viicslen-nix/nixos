# Tasks: Extract Hyprland Desktop Configuration to Separate Flake

**Input**: Design documents from `/specs/002-hyprland-flake/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Comprehensive testing strategy defined in quickstart.md with pre-migration baseline, progressive validation, and post-migration verification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. Hyprland has significantly more complexity than niri with 30+ modules and 10 external inputs.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is a NixOS configuration migration:
- **Flake directory**: `flakes/hyprland/`
- **Module files**: `.nix` configuration files (30+ modules)
- **Main flake**: `/etc/nixos/flake.nix`
- **Old module location**: `modules/nixos/desktop/hyprland/`
- **Module structure**: `config/` (6 modules) + `components/` (20+ modules) + `default.nix`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create directory structure and prepare for migration

- [x] T001 Create flakes/hyprland/ directory structure
- [x] T002 Create flakes/hyprland/config/ subdirectory for core hyprland modules
- [x] T003 Create flakes/hyprland/components/ subdirectory for component modules
- [x] T004 Initialize git tracking for flakes/hyprland/ directory

**Checkpoint**: Directory structure ready for flake files

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create core flake structure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Create flakes/hyprland/flake.nix with 11 inputs (nixpkgs, hyprland, waybar, pyprland, hyprland-contrib, hyprland-plugins, hyprpanel, hypridle, hyprpaper, hyprspace, hyprsplit, hyprchroma)
- [x] T006 Configure nixosModules.default output in flakes/hyprland/flake.nix
- [x] T007 Add descriptive comments to flakes/hyprland/flake.nix for complex input structure
- [x] T008 Set up nixpkgs follows for all inputs in flakes/hyprland/flake.nix
- [x] T009 Run nix flake lock in flakes/hyprland/ to generate flake.lock

**Checkpoint**: Foundation ready - flake structure exists and evaluates, user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Isolated Hyprland Configuration Management (Priority: P1) 🎯 MVP

**Goal**: Enable hyprland flake to build independently and be consumed by main NixOS configuration

**Independent Test**: `nix build ./flakes/hyprland` succeeds and `nix flake show ./flakes/hyprland` displays nixosModules outputs

### Core Module Migration for User Story 1

- [x] T010 [P] [US1] Copy modules/nixos/desktop/hyprland/default.nix to flakes/hyprland/default.nix
- [x] T011 [P] [US1] Copy modules/nixos/desktop/hyprland/config/binds.nix to flakes/hyprland/config/binds.nix
- [x] T012 [P] [US1] Copy modules/nixos/desktop/hyprland/config/env.nix to flakes/hyprland/config/env.nix
- [x] T013 [P] [US1] Copy modules/nixos/desktop/hyprland/config/rules.nix to flakes/hyprland/config/rules.nix
- [x] T014 [P] [US1] Copy modules/nixos/desktop/hyprland/config/settings.nix to flakes/hyprland/config/settings.nix
- [x] T015 [P] [US1] Copy modules/nixos/desktop/hyprland/config/plugins.nix to flakes/hyprland/config/plugins.nix
- [x] T016 [P] [US1] Copy modules/nixos/desktop/hyprland/config/pyprland.nix to flakes/hyprland/config/pyprland.nix

### Component Modules Migration for User Story 1

- [x] T017 [P] [US1] Copy modules/nixos/desktop/hyprland/components/waybar/ directory to flakes/hyprland/components/waybar/
- [x] T018 [P] [US1] Copy modules/nixos/desktop/hyprland/components/rofi/ directory to flakes/hyprland/components/rofi/
- [x] T019 [P] [US1] Copy modules/nixos/desktop/hyprland/components/swaync.nix to flakes/hyprland/components/swaync.nix
- [x] T020 [P] [US1] Copy modules/nixos/desktop/hyprland/components/hyprpaper.nix to flakes/hyprland/components/hyprpaper.nix
- [x] T021 [P] [US1] Copy modules/nixos/desktop/hyprland/components/hypridle.nix to flakes/hyprland/components/hypridle.nix
- [x] T022 [P] [US1] Copy modules/nixos/desktop/hyprland/components/wofi.nix to flakes/hyprland/components/wofi.nix
- [x] T023 [P] [US1] Copy modules/nixos/desktop/hyprland/components/wlogout.nix to flakes/hyprland/components/wlogout.nix
- [x] T024 [P] [US1] Copy modules/nixos/desktop/hyprland/components/hyprlock.nix to flakes/hyprland/components/hyprlock.nix
- [x] T025 [P] [US1] Copy remaining component modules (grimblast, xdg-portals, polkit, etc.) to flakes/hyprland/components/

### Input References Update for User Story 1

- [x] T026 [US1] Update flakes/hyprland/default.nix imports section to reference inputs.hyprland instead of nixpkgs.hyprland
- [x] T027 [US1] Update flakes/hyprland/config/plugins.nix to use inputs.hyprland-plugins
- [x] T028 [US1] Update flakes/hyprland/config/pyprland.nix to use inputs.pyprland
- [x] T029 [US1] Update flakes/hyprland/components/waybar/ to use inputs.waybar
- [x] T030 [US1] Update flakes/hyprland/components/hyprpaper.nix to use inputs.hyprpaper
- [x] T031 [US1] Update flakes/hyprland/components/hypridle.nix to use inputs.hypridle
- [x] T032 [US1] Update any other component references to use appropriate flake inputs
- [x] T033 [US1] Verify all relative path imports are correct in flakes/hyprland/default.nix (./config/, ./components/)

### Option and Pattern Preservation for User Story 1

- [x] T034 [US1] Preserve all module option descriptions in flakes/hyprland/default.nix
- [x] T035 [US1] Preserve preference fallback patterns in all config/ modules
- [x] T036 [US1] Preserve home-manager sharedModules patterns in all components
- [x] T037 [US1] Ensure gnomeCompatibility option logic preserved correctly

### Main Flake Integration for User Story 1

- [x] T038 [US1] Update /etc/nixos/flake.nix inputs section to add hyprland-flake path input
- [x] T039 [US1] Remove hyprland input from /etc/nixos/flake.nix inputs section
- [x] T040 [US1] Remove waybar input from /etc/nixos/flake.nix inputs section
- [x] T041 [US1] Remove pyprland input from /etc/nixos/flake.nix inputs section
- [x] T042 [US1] Remove hyprland-contrib input from /etc/nixos/flake.nix inputs section
- [x] T043 [US1] Remove hyprland-plugins input from /etc/nixos/flake.nix inputs section
- [x] T044 [US1] Remove hyprpanel input from /etc/nixos/flake.nix inputs section
- [x] T045 [US1] Remove hypridle input from /etc/nixos/flake.nix inputs section
- [x] T046 [US1] Remove hyprpaper input from /etc/nixos/flake.nix inputs section
- [x] T047 [US1] Remove hyprspace input from /etc/nixos/flake.nix inputs section
- [x] T048 [US1] Remove hyprsplit input from /etc/nixos/flake.nix inputs section
- [x] T049 [US1] Remove hyprchroma input from /etc/nixos/flake.nix inputs section

### Host Configuration Updates for User Story 1

- [x] T050 [US1] Update hosts/asus-zephyrus-gu603/default.nix to import inputs.hyprland-flake.nixosModules.default
- [x] T051 [US1] Update hosts/home-desktop/default.nix to import inputs.hyprland-flake.nixosModules.default
- [x] T052 [US1] Update modules/nixos/desktop/default.nix to remove hyprland module export
- [x] T053 [US1] Update modules/nixos/all.nix to remove hyprland module import if present

### Validation for User Story 1

- [ ] T054 [US1] Run nix flake check ./flakes/hyprland to validate flake evaluation
- [ ] T055 [US1] Run nix flake show ./flakes/hyprland to verify nixosModules output
- [ ] T056 [US1] Run nix flake metadata ./flakes/hyprland to verify all 11 inputs present
- [ ] T057 [US1] Run nix build ./flakes/hyprland to verify independent build
- [ ] T058 [US1] Run nixos-rebuild build --flake .#asus-zephyrus-gu603 to verify integration
- [ ] T059 [US1] Run nixos-rebuild build --flake .#home-desktop to verify integration

### Functional Testing for User Story 1

- [ ] T060 [US1] Test hyprland desktop environment starts correctly
- [ ] T061 [US1] Test all keybindings (Super+Return, Super+Q, workspace switching, etc.)
- [ ] T062 [US1] Test waybar displays correctly with all modules (workspaces, tray, clock, etc.)
- [ ] T063 [US1] Test rofi launcher works with correct theme
- [ ] T064 [US1] Test window rules apply correctly (floating windows, opacity, etc.)
- [ ] T065 [US1] Test notification daemon (swaync) displays notifications correctly
- [ ] T066 [US1] Test hypridle triggers screen locking correctly
- [ ] T067 [US1] Test hyprpaper sets wallpaper correctly
- [ ] T068 [US1] Test plugin functionality if enabled (hyprland-plugins)
- [ ] T069 [US1] Test home-manager integration applies user configurations

### Cleanup for User Story 1

- [ ] T070 [US1] Remove modules/nixos/desktop/hyprland/ directory after successful validation

**Checkpoint**: User Story 1 complete - hyprland flake builds independently and integrates with main configuration

---

## Phase 4: User Story 2 - Version Independence (Priority: P2)

**Goal**: Enable independent updates of hyprland flake without affecting main flake

**Independent Test**: `cd flakes/hyprland && nix flake update` succeeds and `git diff /etc/nixos/flake.lock` shows no changes

### Implementation for User Story 2

- [ ] T071 [US2] Verify flakes/hyprland/flake.lock exists and is tracked in git
- [ ] T072 [US2] Run cd flakes/hyprland && nix flake update to update hyprland dependencies
- [ ] T073 [US2] Verify /etc/nixos/flake.lock unchanged after hyprland update using git diff flake.lock
- [ ] T074 [US2] Run nixos-rebuild build --flake .#asus-zephyrus-gu603 to verify build with updated hyprland
- [ ] T075 [US2] Run nixos-rebuild build --flake .#home-desktop to verify build with updated hyprland
- [ ] T076 [US2] Test hyprland session still functions correctly after update
- [ ] T077 [US2] Test selective input updates (nix flake update --input hyprland)
- [ ] T078 [US2] Test selective input updates (nix flake update --input waybar)
- [ ] T079 [US2] Document update procedure in flakes/hyprland/README.md (create if doesn't exist)

**Checkpoint**: User Stories 1 AND 2 complete - hyprland can update without affecting main flake

---

## Phase 5: User Story 3 - Reusable Hyprland Modules (Priority: P3)

**Goal**: Ensure hyprland flake can be consumed by other configurations via standard flake inputs

**Independent Test**: Flake outputs are properly structured with nixosModules.default exposed

### Implementation for User Story 3

- [ ] T080 [US3] Verify nixosModules.default output is properly exposed in flakes/hyprland/flake.nix
- [ ] T081 [US3] Add descriptive flake description in flakes/hyprland/flake.nix
- [ ] T082 [US3] Create flakes/hyprland/README.md with comprehensive usage instructions
- [ ] T083 [US3] Document hyprland module options (enable, gnomeCompatibility, etc.) in README.md
- [ ] T084 [US3] Document component configuration options in README.md
- [ ] T085 [US3] Add example configuration snippet to flakes/hyprland/README.md
- [ ] T086 [US3] Document how to consume hyprland flake from another configuration
- [ ] T087 [US3] Document available inputs and their purposes in README.md
- [ ] T088 [US3] Verify flake can be referenced via different input methods (path, git, github) in documentation

**Checkpoint**: All user stories complete - hyprland flake is fully reusable and documented

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final validation

- [ ] T089 [P] Run all quickstart.md pre-migration baseline tests
- [ ] T090 [P] Run all quickstart.md post-migration validation tests
- [ ] T091 [P] Run all quickstart.md independent update tests
- [ ] T092 [P] Verify performance requirements met (flake evaluation < 10s, updates < 60s)
- [ ] T093 [P] Update /etc/nixos/README.md to reference flakes/hyprland/ instead of modules/nixos/desktop/hyprland/
- [ ] T094 [P] Verify no references to old module path remain using grep -r "modules/nixos/desktop/hyprland" /etc/nixos/
- [ ] T095 [P] Verify hyprland flake structure follows established pattern for consistency
- [ ] T096 Add git commit with message "feat: extract hyprland to separate flake"
- [ ] T097 Update any host-specific documentation that references hyprland configuration

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User Story 1 (P1) can start immediately after Phase 2 - This is the MVP
  - User Story 2 (P2) depends on User Story 1 being complete (needs working flake to test updates)
  - User Story 3 (P3) depends on User Story 1 being complete (needs working flake to document)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Depends on User Story 1 completion - Needs working hyprland flake
- **User Story 3 (P3)**: Depends on User Story 1 completion - Needs working hyprland flake

### Within Each User Story

**User Story 1 Flow**:
1. Copy all modules in parallel (T010-T025)
2. Update input references (T026-T033)
3. Preserve patterns and options (T034-T037)
4. Update main flake inputs sequentially (T038-T049)
5. Update host configurations (T050-T053)
6. Validate flake structure (T054-T059)
7. Functional testing (T060-T069)
8. Cleanup (T070)

**User Story 2 Flow**:
1. Verify independent flake.lock (T071-T073)
2. Test integration with updates (T074-T076)
3. Test selective updates (T077-T078)
4. Document procedures (T079)

**User Story 3 Flow**:
1. Verify outputs (T080-T081)
2. Create comprehensive documentation (T082-T089)

### Parallel Opportunities

**Phase 1 (Setup)**:
- T001-T004 sequential (create directories and track)

**Phase 2 (Foundational)**:
- All tasks must run sequentially (each depends on previous)

**Phase 3 (User Story 1)**:
- T010-T025 can run in parallel (copying 16 different modules/directories)
- T038-T049 can run in parallel (removing 11 different inputs from main flake)
- T050-T053 can run in parallel (updating 4 different configuration files)
- T054-T059 can run in parallel (6 different validation commands)
- T060-T069 should run sequentially (functional testing has dependencies)

**Phase 4 (User Story 2)**:
- T074-T075 can run in parallel (testing 2 different hosts)
- T077-T078 can run in parallel (testing 2 different selective updates)

**Phase 5 (User Story 3)**:
- T082-T088 can run in parallel after T081 (creating different documentation sections)

**Phase 6 (Polish)**:
- T089-T095 can run in parallel (independent validation and cleanup tasks)
