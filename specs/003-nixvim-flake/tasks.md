# Tasks: NixVim Standalone Flake

**Input**: Design documents from `/specs/003-nixvim-flake/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Not explicitly requested - excluded from task list.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single flake project**: `flakes/nixvim/` at repository root
- **Config modules**: `flakes/nixvim/config/`
- **Custom packages**: `flakes/nixvim/pkgs/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and flake structure

- [x] T001 Create flake directory structure at `flakes/nixvim/`
- [x] T002 Create flake.nix with inputs (nixpkgs, nixvim, flake-parts, mcphub-nvim) at `flakes/nixvim/flake.nix`
- [x] T003 [P] Create README.md with usage documentation at `flakes/nixvim/README.md`
- [x] T004 [P] Create packages.nix for package outputs at `flakes/nixvim/packages.nix`
- [x] T005 [P] Create apps.nix for app definitions at `flakes/nixvim/apps.nix`

---

## Phase 2: Foundational (Custom Plugin Packages)

**Purpose**: Build custom plugin packages that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No configuration work can begin until these packages exist

- [x] T006 [P] Create laravel-nvim package at `flakes/nixvim/pkgs/laravel-nvim.nix`
- [x] T007 [P] Create worktrees-nvim package at `flakes/nixvim/pkgs/worktrees-nvim.nix`
- [x] T008 [P] Create neotest-pest package at `flakes/nixvim/pkgs/neotest-pest.nix`
- [x] T009 [P] Create mcp-hub packages (mcphub-nvim plugin + mcp-hub CLI) at `flakes/nixvim/pkgs/mcp-hub.nix`
- [x] T010 Create config directory and base module structure at `flakes/nixvim/config/default.nix`

**Checkpoint**: Foundation ready - all custom plugins built and base config module exists

---

## Phase 3: User Story 1 - Build and Run NixVim Configuration (Priority: P1) 🎯 MVP

**Goal**: Create a buildable and runnable NixVim configuration with core options

**Independent Test**: Run `nix build .#default` and `nix run .#default` from `flakes/nixvim/`

### Implementation for User Story 1

- [x] T011 [US1] Configure core Neovim options (opts: tabstop, shiftwidth, etc.) in `flakes/nixvim/config/default.nix`
- [x] T012 [US1] Configure OneDark colorscheme with transparency in `flakes/nixvim/config/default.nix`
- [x] T013 [US1] Enable TreeSitter with auto-install in `flakes/nixvim/config/default.nix`
- [x] T014 [US1] Wire up makeNixvimWithModule in flake.nix to import config module at `flakes/nixvim/flake.nix`
- [x] T015 [US1] Add devShell with nix-output-monitor and alejandra at `flakes/nixvim/flake.nix`
- [x] T016 [US1] Run `nix flake check` and `nix build .#default` to verify MVP builds

**Checkpoint**: At this point, User Story 1 should be fully functional - Neovim launches with base config

---

## Phase 4: User Story 2 - Language Server Support Parity (Priority: P1)

**Goal**: Configure all 17 LSP servers matching the nvf configuration

**Independent Test**: Open files of each supported type and run `:LspInfo` to verify attachment

### Implementation for User Story 2

- [x] T017 [US2] Enable LSP plugin with base configuration in `flakes/nixvim/config/default.nix`
- [x] T018 [P] [US2] Configure Nix LSP (nil_ls) in `flakes/nixvim/config/default.nix`
- [x] T019 [P] [US2] Configure PHP LSP (intelephense) with license key support in `flakes/nixvim/config/default.nix`
- [x] T020 [P] [US2] Configure TypeScript LSP (ts_ls) in `flakes/nixvim/config/default.nix`
- [x] T021 [P] [US2] Configure Python LSP (pyright) in `flakes/nixvim/config/default.nix`
- [x] T022 [P] [US2] Configure Go LSP (gopls) in `flakes/nixvim/config/default.nix`
- [x] T023 [P] [US2] Configure Lua LSP (lua_ls) in `flakes/nixvim/config/default.nix`
- [x] T024 [P] [US2] Configure Bash LSP (bashls) in `flakes/nixvim/config/default.nix`
- [x] T025 [P] [US2] Configure HTML/CSS/Tailwind LSPs in `flakes/nixvim/config/default.nix`
- [x] T026 [P] [US2] Configure Terraform/HCL LSP (terraformls) in `flakes/nixvim/config/default.nix`
- [x] T027 [P] [US2] Configure Markdown LSP (marksman) in `flakes/nixvim/config/default.nix`
- [x] T028 [P] [US2] Configure SQL LSP (sqls) in `flakes/nixvim/config/default.nix`
- [x] T029 [P] [US2] Configure C/C++ LSP (clangd) in `flakes/nixvim/config/default.nix`
- [x] T030 [P] [US2] Configure Zig LSP (zls) in `flakes/nixvim/config/default.nix`
- [ ] T031 [US2] Verify all LSP servers attach correctly to their file types

**Checkpoint**: At this point, User Story 2 complete - all 17 language servers functional

---

## Phase 5: User Story 3 - Keybind Parity (Priority: P2)

**Goal**: Configure identical keybindings to nvf configuration

**Independent Test**: Execute each documented keybind and verify expected action

### Implementation for User Story 3

- [x] T032 [US3] Create keybinds module at `flakes/nixvim/config/keybinds.nix`
- [x] T033 [US3] Import keybinds module into config/default.nix at `flakes/nixvim/config/default.nix`
- [x] T034 [US3] Configure file operations keybinds (save, close buffer) in `flakes/nixvim/config/keybinds.nix`
- [x] T035 [US3] Configure LSP keybinds (gd, gD, gt, gr, gi, h) in `flakes/nixvim/config/keybinds.nix`
- [x] T036 [US3] Configure buffer navigation keybinds (Tab, S-Tab, leader-x) in `flakes/nixvim/config/keybinds.nix`
- [x] T037 [US3] Configure editing keybinds (comment, indent, semicolon append) in `flakes/nixvim/config/keybinds.nix`
- [x] T038 [US3] Configure telescope keybinds (find files, grep, buffers) in `flakes/nixvim/config/keybinds.nix`
- [x] T039 [US3] Configure git keybinds (fugitive, gitlinker, worktrees) in `flakes/nixvim/config/keybinds.nix`
- [x] T040 [US3] Configure Laravel plugin keybinds (lla, llr, llm) in `flakes/nixvim/config/keybinds.nix`
- [ ] T041 [US3] Verify keybinds work with which-key integration

**Checkpoint**: At this point, User Story 3 complete - all keybinds match nvf

---

## Phase 6: User Story 4 - Plugin Parity (Priority: P2)

**Goal**: Configure all plugins including custom integrations

**Independent Test**: Load each plugin and verify commands/features work

### Implementation for User Story 4

#### UI Plugins
- [x] T042 [P] [US4] Enable telescope with extensions in `flakes/nixvim/config/default.nix`
- [x] T043 [P] [US4] Enable bufferline in `flakes/nixvim/config/default.nix`
- [x] T044 [P] [US4] Enable nvim-tree with git integration in `flakes/nixvim/config/default.nix`
- [x] T045 [P] [US4] Enable lualine statusline in `flakes/nixvim/config/default.nix`
- [x] T046 [P] [US4] Enable alpha dashboard in `flakes/nixvim/config/default.nix`
- [x] T047 [P] [US4] Enable which-key in `flakes/nixvim/config/default.nix`
- [x] T048 [P] [US4] Enable notify in `flakes/nixvim/config/default.nix`

#### Productivity Plugins
- [x] T049 [P] [US4] Enable comment-nvim in `flakes/nixvim/config/default.nix`
- [x] T050 [P] [US4] Enable nvim-autopairs in `flakes/nixvim/config/default.nix`
- [x] T051 [P] [US4] Enable leap.nvim in `flakes/nixvim/config/default.nix`
- [x] T052 [P] [US4] Enable nvim-surround in `flakes/nixvim/config/default.nix`

#### Git Plugins
- [x] T053 [P] [US4] Enable gitsigns in `flakes/nixvim/config/default.nix`
- [x] T054 [P] [US4] Enable vim-fugitive in `flakes/nixvim/config/default.nix`
- [x] T055 [P] [US4] Enable git-conflict in `flakes/nixvim/config/default.nix`
- [x] T056 [P] [US4] Enable gitlinker in `flakes/nixvim/config/default.nix`

#### Completion & AI
- [x] T057 [P] [US4] Enable nvim-cmp with LSP source in `flakes/nixvim/config/default.nix`
- [x] T058 [P] [US4] Enable copilot-lua with cmp integration in `flakes/nixvim/config/default.nix`
- [x] T059 [P] [US4] Enable avante with provider config in `flakes/nixvim/config/default.nix`

#### Debugging & Terminal
- [x] T060 [P] [US4] Enable nvim-dap with UI in `flakes/nixvim/config/default.nix`
- [x] T061 [P] [US4] Enable toggleterm with lazygit integration in `flakes/nixvim/config/default.nix`

#### Custom Plugins (extraPlugins)
- [x] T062 [US4] Add laravel.nvim to extraPlugins with setup in `flakes/nixvim/config/default.nix`
- [x] T063 [US4] Add worktrees.nvim to extraPlugins with telescope extension in `flakes/nixvim/config/default.nix`
- [x] T064 [US4] Add neotest with neotest-pest adapter in `flakes/nixvim/config/default.nix`
- [x] T065 [US4] Add mcphub.nvim to extraPlugins with Avante integration (uses __raw for callbacks) in `flakes/nixvim/config/default.nix`
- [x] T066 [US4] Add mcp-hub CLI to extraPackages in `flakes/nixvim/config/default.nix`
- [ ] T067 [US4] Verify all plugins load without errors via `:Lazy`

**Checkpoint**: At this point, User Story 4 complete - all plugins functional

---

## Phase 7: User Story 5 - UI/Visual Parity (Priority: P3)

**Goal**: Fine-tune visual elements to match nvf configuration

**Independent Test**: Visual comparison of theme, statusline, bufferline, file explorer

### Implementation for User Story 5

- [x] T068 [US5] Configure OneDark theme style (darker) and transparency settings in `flakes/nixvim/config/default.nix`
- [x] T069 [US5] Configure lualine sections and theme matching in `flakes/nixvim/config/default.nix`
- [x] T070 [US5] Configure bufferline appearance and options in `flakes/nixvim/config/default.nix`
- [x] T071 [US5] Configure nvim-tree appearance and icons in `flakes/nixvim/config/default.nix`
- [x] T072 [US5] Configure alpha dashboard layout in `flakes/nixvim/config/default.nix`
- [ ] T073 [US5] Visual verification against nvf configuration

**Checkpoint**: At this point, User Story 5 complete - visual parity achieved

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and documentation

- [x] T074 [P] Run `nix flake check` for final validation at `flakes/nixvim/`
- [x] T075 [P] Format all Nix files with alejandra at `flakes/nixvim/`
- [x] T076 [P] Update README.md with final usage instructions at `flakes/nixvim/README.md`
- [ ] T077 Run quickstart.md validation checklist
- [x] T078 Lock flake dependencies with `nix flake lock` at `flakes/nixvim/`
- [x] T079 Final build and run test: `nix build .#default && nix run .#default`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on T002 (flake.nix exists) - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational completion
- **User Story 2 (Phase 4)**: Depends on Phase 3 (config structure exists)
- **User Story 3 (Phase 5)**: Depends on Phase 3 (config structure exists)
- **User Story 4 (Phase 6)**: Depends on Phase 2 (custom plugins built), Phase 3 (config exists)
- **User Story 5 (Phase 7)**: Depends on Phase 6 (plugins enabled)
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Foundational only - MVP buildable configuration
- **User Story 2 (P1)**: Foundational + US1 - LSP configuration
- **User Story 3 (P2)**: Foundational + US1 - Can be parallel with US2/US4
- **User Story 4 (P2)**: Foundational + US1 - Can be parallel with US2/US3
- **User Story 5 (P3)**: US4 must complete first (needs plugins to configure visuals)

### Within Each User Story

- Models/packages before configuration
- Core config before plugin-specific config
- Story complete before moving to next priority

### Parallel Opportunities

- T003, T004, T005 can run in parallel (Setup phase)
- T006, T007, T008, T009 can run in parallel (custom packages)
- T018-T030 can run in parallel (LSP servers are independent)
- T042-T061 can run in parallel (plugin enables are independent)
- T074, T075, T076 can run in parallel (Polish phase)

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Launch all custom package builds in parallel:
Task: "Create laravel-nvim package at flakes/nixvim/pkgs/laravel-nvim.nix"
Task: "Create worktrees-nvim package at flakes/nixvim/pkgs/worktrees-nvim.nix"
Task: "Create neotest-pest package at flakes/nixvim/pkgs/neotest-pest.nix"
Task: "Create mcp-hub packages at flakes/nixvim/pkgs/mcp-hub.nix"
```

## Parallel Example: Phase 4 (LSP Configuration)

```bash
# Launch all LSP server configurations in parallel:
Task: "Configure Nix LSP (nil_ls)"
Task: "Configure PHP LSP (intelephense)"
Task: "Configure TypeScript LSP (ts_ls)"
# ... all T018-T030 can run simultaneously
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational packages (T006-T010)
3. Complete Phase 3: User Story 1 - Basic build/run (T011-T016)
4. **STOP and VALIDATE**: `nix run .#default` works, Neovim launches
5. Complete Phase 4: User Story 2 - LSP parity (T017-T031)
6. **STOP and VALIDATE**: All LSP servers attach correctly
7. Deploy/demo if ready - this is a functional dev environment!

### Incremental Delivery

1. Setup + Foundational → Packages built
2. User Story 1 (P1) → Basic Neovim works → **MVP Ready!**
3. User Story 2 (P1) → Full LSP support → **Dev-Ready!**
4. User Story 3 (P2) → Keybind parity → Muscle memory works
5. User Story 4 (P2) → Full plugin parity → Feature complete
6. User Story 5 (P3) → Visual parity → Polish complete

### Single Developer Strategy

1. Complete phases sequentially in priority order
2. Stop at any checkpoint to validate
3. Each user story adds value without breaking previous

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- All plugin configuration happens in `config/default.nix` (can be split later if needed)
- Custom plugins require `extraPlugins` + `extraConfigLua` for setup
- MCPHub is the only plugin requiring `__raw` Lua due to dynamic callbacks
- Verify `nix flake check` passes after each phase
- Commit after each task or logical group
