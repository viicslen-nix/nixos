# Implementation Plan: NixVim Standalone Flake

**Branch**: `003-nixvim-flake` | **Date**: December 8, 2025 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-nixvim-flake/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Create a standalone NixVim flake at `flakes/nixvim/` that mirrors the existing nvf Neovim configuration with identical plugins, keybinds, and LSP servers. The flake will use NixVim's native option system (avoiding raw Lua where possible) and provide a complete, buildable Neovim package with OneDark theme, full LSP support, and all productivity plugins.

## Technical Context

**Language/Version**: Nix (NixVim framework from github:nix-community/nixvim)
**Primary Dependencies**: nixvim, flake-parts, nixpkgs (nixos-unstable)
**Storage**: N/A (declarative configuration only)
**Testing**: `nix flake check`, manual functional verification
**Target Platform**: x86_64-linux (standalone Neovim package)
**Project Type**: Single flake project with modular configuration
**Performance Goals**: Neovim startup < 500ms, immediate LSP attachment
**Constraints**: Must use NixVim native options; avoid `__raw` Lua except for MCPHub dynamic callbacks
**Scale/Scope**: Single user development environment, ~15 LSP servers, ~30 plugins

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Modular Configuration Design | ✅ PASS | Flake organized with `config/`, `pkgs/` subdirectories; each concern separated |
| II. Declarative System State Management | ✅ PASS | All configuration expressed in NixVim options, no imperative setup |
| III. Multi-Host Compatibility | ✅ PASS | Standalone flake consumable by any NixOS host via flake input |
| IV. Flake-Based Reproducibility | ✅ PASS | Uses flake-parts, pins nixpkgs via `inputs.nixpkgs.follows` |
| V. Preference Fallback Patterns | ✅ PASS | Uses NixVim defaults with explicit overrides |
| VI. Documentation & Maintainability | ✅ PASS | Includes README.md, spec documentation in `specs/003-nixvim-flake/` |
| VII. Code Clarity Over Cleverness | ✅ PASS | Prefers NixVim native options over raw Lua; only exception documented |
| VIII. Consistent User Interface Patterns | ✅ PASS | Keybinds mirror existing nvf config exactly |

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
flakes/nixvim/
├── flake.nix            # Flake definition with inputs, outputs, flake-parts
├── flake.lock           # Pinned dependency versions
├── README.md            # Usage documentation
├── config/
│   ├── default.nix      # Main NixVim configuration module
│   └── keybinds.nix     # Keybind definitions (imports into default.nix)
└── pkgs/
    ├── laravel-nvim.nix # Custom Laravel.nvim package
    ├── worktrees-nvim.nix # Custom worktrees.nvim package
    ├── neotest-pest.nix # Custom neotest-pest package
    └── mcp-hub.nix      # MCPHub plugin and CLI packages
```

**Structure Decision**: Single flake with `config/` for NixVim configuration modules and `pkgs/` for custom plugin derivations. Mirrors existing nvf flake structure for consistency.

## Complexity Tracking

> **No violations** - All constitution checks pass. Single flake with clear separation of concerns.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Raw Lua for MCPHub | Dynamic runtime callbacks for MCP server communication | NixVim has no native MCPHub module; function callbacks cannot be expressed declaratively |
