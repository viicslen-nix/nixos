# Feature Specification: NixVim Standalone Flake

**Feature Branch**: `003-nixvim-flake`
**Created**: December 8, 2025
**Status**: Draft
**Input**: User description: "Add another local flake in the flakes directory which uses nixvim instead of nvf to configure vim using nix as a standalone flake. It should use the same keybinds and plugins as the ones used in the nvf flake"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Build and Run NixVim Configuration (Priority: P1)

As a NixOS user, I want to build and run a Neovim instance configured with NixVim that provides the same functionality as my existing nvf configuration, so that I can evaluate NixVim as an alternative configuration framework.

**Why this priority**: This is the core functionality - without being able to build and run the NixVim-based Neovim, no other features matter.

**Independent Test**: Can be fully tested by running `nix run .#default` from the flake directory and verifying Neovim launches with the expected configuration.

**Acceptance Scenarios**:

1. **Given** the nixvim flake exists in `flakes/nixvim/`, **When** I run `nix build .#default`, **Then** a Neovim package is built successfully without errors
2. **Given** the flake is built, **When** I run `nix run .#default`, **Then** Neovim launches with the configured theme, plugins, and keybinds
3. **Given** the flake is built, **When** I check the output, **Then** it provides a standalone Neovim executable that works independently of the host NixOS configuration

---

### User Story 2 - Language Server Support Parity (Priority: P1)

As a developer, I want the NixVim configuration to include all the same language servers and language support as the nvf configuration, so that I have consistent development capabilities across both configurations.

**Why this priority**: Language server support is essential for a usable development environment.

**Independent Test**: Can be fully tested by opening files of each supported language type and verifying LSP features work (completion, diagnostics, go-to-definition).

**Acceptance Scenarios**:

1. **Given** Neovim is running with the NixVim config, **When** I open a Nix file, **Then** I get syntax highlighting, completion, and diagnostics
2. **Given** Neovim is running, **When** I open files for PHP, TypeScript, Python, Go, Lua, Bash, HTML, CSS, Tailwind, Terraform, HCL, Markdown, SQL, Nu, and Zig, **Then** each language has working LSP support
3. **Given** Neovim is running with a PHP file, **When** I check the LSP status, **Then** Intelephense is the active language server

---

### User Story 3 - Keybind Parity (Priority: P2)

As a user migrating between configurations, I want the same keybindings in NixVim as in nvf, so that my muscle memory works consistently.

**Why this priority**: Consistent keybinds reduce friction when switching between configurations, but the system is usable with default keybinds.

**Independent Test**: Can be fully tested by executing each documented keybind and verifying it performs the expected action.

**Acceptance Scenarios**:

1. **Given** Neovim is running, **When** I press `<C-s>` in any mode, **Then** the current file is saved
2. **Given** Neovim is running, **When** I press `<leader>gd`, **Then** I go to the definition of the symbol under cursor
3. **Given** Neovim is running with a buffer, **When** I press `<Tab>`, **Then** I cycle to the next buffer
4. **Given** I have multiple lines selected, **When** I press `>` or `<`, **Then** the selection is indented/unindented and selection is preserved
5. **Given** Neovim is running, **When** I press `<leader>;` in normal mode, **Then** a semicolon is appended to the current line
6. **Given** Neovim is running, **When** I press `<C-/>`, **Then** the current line is commented/uncommented

---

### User Story 4 - Plugin Parity (Priority: P2)

As a power user, I want all my custom plugins and integrations (Laravel, Git Worktrees, MCPHub, Neotest) available in the NixVim configuration, so that I have feature parity with my nvf setup.

**Why this priority**: Custom plugins enhance productivity but the editor is functional without them.

**Independent Test**: Can be fully tested by loading each plugin and verifying its commands/features work.

**Acceptance Scenarios**:

1. **Given** Neovim is running in a Laravel project, **When** I run `:Laravel artisan`, **Then** the Laravel artisan picker opens
2. **Given** Neovim is running in a git repository, **When** I press `<leader>gws`, **Then** the worktrees telescope picker opens
3. **Given** MCPHub is configured, **When** I check Avante integration, **Then** MCP tools are available as custom tools
4. **Given** Neovim is running, **When** I run `:Neotest`, **Then** test discovery and execution work for PHP Pest tests

---

### User Story 5 - UI/Visual Parity (Priority: P3)

As a user, I want the same visual experience (theme, statusline, bufferline, file explorer) in NixVim as in nvf.

**Why this priority**: Visual consistency is nice-to-have but does not affect functionality.

**Independent Test**: Can be fully tested by visual comparison of key UI elements.

**Acceptance Scenarios**:

1. **Given** Neovim is running, **When** I look at the theme, **Then** OneDark (darker variant) with transparency is applied
2. **Given** Neovim is running, **When** I look at the bottom of the screen, **Then** Lualine statusline is visible
3. **Given** Neovim has multiple buffers open, **When** I look at the top, **Then** nvim-bufferline shows open buffers
4. **Given** Neovim is running, **When** I open the file tree, **Then** nvim-tree is displayed with git status indicators

---

### Edge Cases

- What happens when building on a system without unfree packages allowed? (Should work as flake handles its own nixpkgs config)
- How does the flake handle missing external dependencies like language servers? (Should include them in extraPackages)
- What happens when custom plugins fail to build? (Build should fail with clear error messages)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a standalone Nix flake at `flakes/nixvim/` that builds a complete Neovim configuration using NixVim
- **FR-002**: System MUST support the `nix run .#default` command to launch the configured Neovim
- **FR-003**: System MUST support the `nix build .#default` command to build the Neovim package
- **FR-004**: System MUST configure all language servers matching the nvf configuration: Nix, PHP (Intelephense), TypeScript, Python, Go, Lua, Bash, HTML, CSS, Tailwind, Terraform, HCL, Markdown, SQL, Nu, Zig, and Clang
- **FR-005**: System MUST include TreeSitter support for syntax highlighting and code folding
- **FR-006**: System MUST configure the same keybinds as defined in the nvf flake's `config/keybinds.nix`
- **FR-007**: System MUST include the OneDark theme (darker variant) with transparency enabled
- **FR-008**: System MUST include UI plugins: Lualine, nvim-bufferline, nvim-tree, telescope, alpha dashboard
- **FR-009**: System MUST include productivity plugins: comment-nvim, nvim-autopairs, leap.nvim, surround.nvim, which-key
- **FR-010**: System MUST include Git integration: gitsigns, vim-fugitive, git-conflict, gitlinker
- **FR-011**: System MUST include the custom plugins: laravel.nvim, worktrees.nvim, neotest-pest, mcphub.nvim
- **FR-012**: System MUST include AI assistant integration: Copilot, Avante with MCPHub integration
- **FR-013**: System MUST include completion support via nvim-cmp with LSP and Copilot sources
- **FR-014**: System MUST include debugging support via nvim-dap
- **FR-015**: System MUST include terminal integration via toggleterm with lazygit support
- **FR-016**: System MUST provide a development shell with nix-output-monitor and alejandra formatter
- **FR-017**: System MUST use flake-parts for consistent flake structure with other flakes in the repository

### Key Entities

- **Flake**: The Nix flake configuration that defines inputs, outputs, packages, and apps
- **NixVim Configuration**: The declarative Neovim configuration using NixVim's module system
- **Custom Plugins**: vim plugins built from source using `vimUtils.buildVimPlugin` (laravel.nvim, worktrees.nvim, neotest-pest, mcphub.nvim, mcp-hub)
- **Keybind Configuration**: Mappings between key combinations and Neovim actions
- **Language Configuration**: LSP servers, TreeSitter parsers, and formatters for each supported language

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The flake builds successfully on first attempt with `nix build .#default`
- **SC-002**: Neovim launches within 2 seconds when run via `nix run .#default`
- **SC-003**: All 17 language servers are active and functional when opening files of their respective types
- **SC-004**: 100% of keybinds from the nvf configuration work identically in the NixVim configuration
- **SC-005**: All custom plugins (laravel.nvim, worktrees.nvim, neotest-pest, mcphub.nvim) load without errors
- **SC-006**: Code completion suggestions appear within 500ms of typing in any supported language
- **SC-007**: The flake structure follows the same pattern as existing flakes (hyprland, niri) in the repository

## Assumptions

- NixVim provides equivalent functionality to nvf for all required features
- The same custom plugin packages built for nvf can be used with NixVim
- NixVim's module system supports all the plugin configurations needed
- The user has network access to fetch flake inputs during build
- The host system is x86_64-linux (consistent with other flakes in the repository)
