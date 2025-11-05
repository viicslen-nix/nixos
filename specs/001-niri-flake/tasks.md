# Tasks: Extract Niri Desktop Configuration to Separate Flake

**Input**: Design documents from `/specs/001-niri-flake/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: No tests requested in specification. Tasks focus on configuration migration and validation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is a NixOS configuration migration:
- **Flake directory**: `flakes/niri/`
- **Module files**: `.nix` configuration files
- **Main flake**: `/etc/nixos/flake.nix`
- **Old module location**: `modules/nixos/desktop/niri/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create directory structure and prepare for migration

- [X] T001 Create flakes/niri/ directory structure
- [X] T002 Initialize git tracking for flakes/niri/ directory

**Checkpoint**: Directory structure ready for flake files ✓ COMPLETE

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create core flake structure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T003 Create flakes/niri/flake.nix with inputs (nixpkgs, niri-flake, dankMaterialShell, dgop, dms-cli)
- [X] T004 Configure nixosModules.default and nixosModules.niri outputs in flakes/niri/flake.nix
- [X] T005 Add descriptive comments to flakes/niri/flake.nix outputs section
- [X] T006 Run nix flake lock in flakes/niri/ to generate flake.lock

**Checkpoint**: Foundation ready - flake structure exists and evaluates, user story implementation can now begin in parallel ✓ COMPLETE

---

## Phase 3: User Story 1 - Isolated Niri Configuration Management (Priority: P1) 🎯 MVP

**Goal**: Enable niri flake to build independently and be consumed by main NixOS configuration

**Independent Test**: `nix build ./flakes/niri` succeeds and `nix flake show ./flakes/niri` displays nixosModules outputs

### Implementation for User Story 1

- [X] T007 [P] [US1] Copy modules/nixos/desktop/niri/default.nix to flakes/niri/default.nix
- [X] T008 [P] [US1] Copy modules/nixos/desktop/niri/binds.nix to flakes/niri/binds.nix
- [X] T009 [P] [US1] Copy modules/nixos/desktop/niri/rules.nix to flakes/niri/rules.nix
- [X] T010 [P] [US1] Copy modules/nixos/desktop/niri/settings.nix to flakes/niri/settings.nix
- [X] T011 [P] [US1] Copy modules/nixos/desktop/niri/shell.nix to flakes/niri/shell.nix
- [X] T012 [US1] Update flakes/niri/default.nix imports section to use inputs.niri-flake instead of inputs.niri
- [X] T013 [US1] Update flakes/niri/shell.nix imports to use inputs.dankMaterialShell
- [X] T014 [US1] Verify all relative path imports (./binds.nix, ./rules.nix, ./settings.nix, ./shell.nix) are correct in flakes/niri/default.nix
- [X] T015 [US1] Preserve preference fallback pattern in flakes/niri/binds.nix (cfg.terminal -> defaults.terminal -> null)
- [X] T016 [US1] Ensure all module option descriptions are preserved in flakes/niri/default.nix
- [X] T017 [US1] Update /etc/nixos/flake.nix inputs section to add niri path input
- [X] T018 [US1] Remove niri-flake input from /etc/nixos/flake.nix inputs section
- [X] T019 [US1] Remove dankMaterialShell input from /etc/nixos/flake.nix inputs section
- [X] T020 [US1] Remove dgop input from /etc/nixos/flake.nix inputs section
- [X] T021 [US1] Remove dms-cli input from /etc/nixos/flake.nix inputs section
- [X] T022 [US1] Run nix flake check ./flakes/niri to validate flake evaluation
- [X] T023 [US1] Run nix flake show ./flakes/niri to verify outputs
- [X] T024 [US1] Run nix flake metadata ./flakes/niri to verify all 5 inputs present
- [X] T025 [US1] Run nix build ./flakes/niri to verify independent build
- [X] T026 [US1] Run nixos-rebuild build --flake .#asus-zephyrus-gu603 to verify integration
- [ ] T027 [US1] Test all keybindings (Mod+Return, Mod+B, Mod+E, etc.) in niri session
- [ ] T028 [US1] Verify window rules apply correctly (Ferdium floating, rounded corners)
- [ ] T029 [US1] Verify compositor settings active (cursor hiding, gaps, borders)
- [ ] T030 [US1] Verify startup applications launch (polkit, gnome-keyring, password manager)
- [ ] T031 [US1] Verify DankMaterialShell loads with correct theme
- [ ] T032 [US1] Remove modules/nixos/desktop/niri/ directory after successful validation
- [X] T033 [US1] Update modules/nixos/desktop/ all.nix or imports if niri module was listed there

**Checkpoint**: At this point, User Story 1 should be fully functional - niri flake builds independently and integrates with main configuration ⚠️ AWAITING FUNCTIONAL TESTING

---

## Phase 4: User Story 2 - Version Independence (Priority: P2)

**Goal**: Enable independent updates of niri flake without affecting main flake

**Independent Test**: `cd flakes/niri && nix flake update` succeeds and `git diff /etc/nixos/flake.lock` shows no changes

### Implementation for User Story 2

- [ ] T034 [US2] Verify flakes/niri/flake.lock exists and is tracked in git
- [ ] T035 [US2] Run cd flakes/niri && nix flake update to update niri dependencies
- [ ] T036 [US2] Verify /etc/nixos/flake.lock unchanged after niri update using git diff flake.lock
- [ ] T037 [US2] Run nixos-rebuild build --flake .#asus-zephyrus-gu603 to verify build with updated niri
- [ ] T038 [US2] Test niri session still functions correctly after update
- [ ] T039 [US2] Document update procedure in flakes/niri/README.md (create if doesn't exist)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - niri can update without affecting main flake

---

## Phase 5: User Story 3 - Reusable Niri Modules (Priority: P3)

**Goal**: Ensure niri flake can be consumed by other configurations via standard flake inputs

**Independent Test**: Flake outputs are properly structured with nixosModules.default exposed

### Implementation for User Story 3

- [ ] T040 [US3] Verify nixosModules.default output is properly exposed in flakes/niri/flake.nix
- [ ] T041 [US3] Verify nixosModules.niri alias exists in flakes/niri/flake.nix outputs
- [ ] T042 [US3] Add flake description in flakes/niri/flake.nix
- [ ] T043 [US3] Create flakes/niri/README.md with usage instructions
- [ ] T044 [US3] Document how to consume niri flake from another configuration in flakes/niri/README.md
- [ ] T045 [US3] Document module options (enable, terminal, browser, etc.) in flakes/niri/README.md
- [ ] T046 [US3] Add example configuration snippet to flakes/niri/README.md
- [ ] T047 [US3] Verify flake can be referenced via different input methods (path, git, github) in documentation

**Checkpoint**: All user stories should now be independently functional - niri flake is fully reusable and documented

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final validation

- [ ] T048 [P] Update /etc/nixos/README.md to reference flakes/niri/ instead of modules/nixos/desktop/niri/
- [ ] T049 [P] Verify no references to old module path remain using grep -r "modules/nixos/desktop/niri" /etc/nixos/
- [ ] T050 [P] Run all quickstart.md validation stages (7 stages total)
- [ ] T051 [P] Verify niri flake structure matches flakes/neovim/ pattern for consistency (SC-006)
- [ ] T052 Add git commit with message "feat: extract niri to separate flake"
- [ ] T053 Update any host-specific documentation that references niri configuration

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User Story 1 (P1) can start immediately after Phase 2
  - User Story 2 (P2) depends on User Story 1 being complete (needs working flake to test updates)
  - User Story 3 (P3) depends on User Story 1 being complete (needs working flake to document)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories - This is the MVP
- **User Story 2 (P2)**: Depends on User Story 1 completion - Needs working niri flake to test independent updates
- **User Story 3 (P3)**: Depends on User Story 1 completion - Needs working niri flake to document reusability

### Within Each User Story

**User Story 1 Flow**:
1. Copy all 5 module files in parallel (T007-T011)
2. Update imports and references (T012-T014)
3. Preserve patterns and options (T015-T016)
4. Update main flake inputs sequentially (T017-T021)
5. Validate flake structure (T022-T025)
6. Integration testing (T026)
7. Functional validation (T027-T031)
8. Cleanup (T032-T033)

**User Story 2 Flow**:
1. Verify flake.lock exists (T034)
2. Test independent update (T035-T036)
3. Verify integration still works (T037-T038)
4. Document procedure (T039)

**User Story 3 Flow**:
1. Verify outputs (T040-T042)
2. Create documentation (T043-T047)

### Parallel Opportunities

**Phase 1 (Setup)**:
- Both tasks can run in sequence (create dir, track in git)

**Phase 2 (Foundational)**:
- All tasks must run sequentially (each depends on previous)

**Phase 3 (User Story 1)**:
- T007-T011 can run in parallel (copying 5 different files)
- T018-T021 can run in parallel (removing 4 different inputs from main flake)

**Phase 4 (User Story 2)**:
- All tasks sequential (each validates previous step)

**Phase 5 (User Story 3)**:
- T040-T042 can run in parallel (verifying 3 different aspects)
- T043-T047 sequential (building documentation)

**Phase 6 (Polish)**:
- T048-T051 can run in parallel (independent documentation and validation tasks)

---

## Parallel Example: User Story 1

```bash
# Copy all module files together (T007-T011):
cp modules/nixos/desktop/niri/default.nix flakes/niri/default.nix &
cp modules/nixos/desktop/niri/binds.nix flakes/niri/binds.nix &
cp modules/nixos/desktop/niri/rules.nix flakes/niri/rules.nix &
cp modules/nixos/desktop/niri/settings.nix flakes/niri/settings.nix &
cp modules/nixos/desktop/niri/shell.nix flakes/niri/shell.nix &
wait

# Remove main flake inputs together (T018-T021):
# Edit /etc/nixos/flake.nix to remove:
# - niri-flake input
# - dankMaterialShell input
# - dgop input
# - dms-cli input
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (2 tasks)
2. Complete Phase 2: Foundational (4 tasks) - CRITICAL
3. Complete Phase 3: User Story 1 (27 tasks)
4. **STOP and VALIDATE**: Test User Story 1 independently using quickstart.md
5. Commit if ready

**Result**: Fully functional niri flake that integrates with main configuration. This alone delivers the core value.

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready (6 tasks)
2. Add User Story 1 → Test independently → Commit (MVP! 27 tasks)
3. Add User Story 2 → Test independently → Commit (6 tasks)
4. Add User Story 3 → Test independently → Commit (8 tasks)
5. Polish → Final validation → Commit (6 tasks)

Each story adds value without breaking previous stories. Total: 53 tasks.

### Single Developer Strategy

Recommended order:
1. Setup (30 minutes)
2. Foundational (1 hour)
3. User Story 1 (2-3 hours including testing)
4. User Story 2 (30 minutes)
5. User Story 3 (1 hour)
6. Polish (30 minutes)

**Total Estimated Time**: 5-7 hours

---

## Validation Checklist

After completing each user story, verify:

### User Story 1 Validation
- [ ] `nix flake check ./flakes/niri` succeeds
- [ ] `nix flake show ./flakes/niri` shows nixosModules outputs
- [ ] `nix flake metadata ./flakes/niri` shows 5 inputs
- [ ] `nix build ./flakes/niri` succeeds
- [ ] `nixos-rebuild build --flake .#asus-zephyrus-gu603` succeeds
- [ ] All keybindings work in niri session
- [ ] Window rules apply correctly
- [ ] Compositor settings are active
- [ ] Startup applications launch
- [ ] DankMaterialShell loads properly

### User Story 2 Validation
- [ ] `cd flakes/niri && nix flake update` succeeds
- [ ] Main flake.lock unchanged after niri update
- [ ] System rebuilds successfully with updated niri
- [ ] Niri still functions after update

### User Story 3 Validation
- [ ] nixosModules.default exposed in flake outputs
- [ ] nixosModules.niri alias exists
- [ ] README.md exists with usage instructions
- [ ] Example configuration documented

---

## Notes

- **[P] tasks**: Different files, no dependencies - can run in parallel
- **[Story] label**: Maps task to specific user story for traceability
- **Each user story**: Independently completable and testable
- **Commit strategy**: Commit after User Story 1 (MVP), then after each additional story
- **Rollback plan**: `sudo nixos-rebuild switch --rollback` if issues occur
- **Testing guide**: Follow quickstart.md for comprehensive validation
- **Constitution compliance**: All tasks align with principles I, IV, VI (Modular Design, Flake Reproducibility, Documentation)

---

## Success Criteria Mapping

| Success Criterion | Validated By Tasks |
|-------------------|-------------------|
| SC-001: Independent build | T025 |
| SC-002: System rebuild succeeds | T026 |
| SC-003: Functionality identical | T027-T031 |
| SC-004: Independent updates | T035-T036 |
| SC-005: Isolated rebuilds | T026, T037 |
| SC-006: Pattern consistency | T051 |

---

**Total Tasks**: 53
**MVP Tasks (US1)**: 33 (Setup + Foundational + US1)
**Parallel Opportunities**: 9 tasks can run in parallel
**Estimated Duration**: 5-7 hours for single developer
**Risk Level**: Low (atomic migration, easy rollback)
