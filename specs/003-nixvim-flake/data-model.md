# Data Model: NixVim Standalone Flake

**Feature Branch**: `003-nixvim-flake`
**Created**: December 8, 2025

## Overview

This feature is a Nix flake configuration that produces a Neovim package. The "data model" represents the structural organization of the flake and its configuration modules.

## Entity Definitions

### 1. Flake (Root)

The top-level Nix flake that defines inputs, outputs, and the overall structure.

**Attributes**:

| Attribute | Type | Description |
|-----------|------|-------------|
| `inputs.nixpkgs` | Flake Input | NixOS packages repository |
| `inputs.nixvim` | Flake Input | NixVim framework |
| `inputs.flake-parts` | Flake Input | Flake composition library |
| `inputs.mcphub-nvim` | Flake Input | MCPHub plugin source |
| `outputs.packages.<system>.default` | Package | Built Neovim with configuration |
| `outputs.apps.<system>.default` | App | Runnable Neovim application |
| `outputs.devShells.<system>.default` | DevShell | Development environment |

**Relationships**:

- Contains -> NixVim Configuration
- Contains -> Custom Plugin Packages

### 2. NixVim Configuration

The declarative Neovim configuration using NixVim's module system.

**Attributes**:

| Attribute | Type | Description |
|-----------|------|-------------|
| `opts` | AttrSet | Neovim options (tabstop, shiftwidth, etc.) |
| `globals` | AttrSet | Vim global variables |
| `keymaps` | List | Key binding definitions |
| `colorschemes.<name>` | Module | Theme configuration |
| `plugins.<name>` | Module | Plugin configurations |
| `extraPlugins` | List | Custom plugins not in NixVim |
| `extraConfigLua` | String | Raw Lua configuration |
| `extraPackages` | List | External tools (LSP servers, etc.) |

**Relationships**:

- Contains -> Keybind Configuration
- Contains -> Language Configuration
- Uses -> Custom Plugins

### 3. Keybind Configuration

Mappings between key combinations and Neovim actions.

**Attributes** (per keymap entry):

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `key` | String | Yes | Key combination (e.g., "<C-s>") |
| `action` | String/Raw | Yes | Action to execute |
| `mode` | String/List | No | Mode(s): n, v, i, etc. (default: n) |
| `options.desc` | String | No | Description for which-key |
| `options.silent` | Bool | No | Silent execution |
| `options.noremap` | Bool | No | Non-recursive mapping |

**Example**:

```nix
{
  key = "<C-s>";
  mode = ["n" "v" "i"];
  action = "<cmd>w<CR>";
  options = {
    desc = "Save file";
    silent = true;
  };
}
```

### 4. Language Configuration

LSP servers, TreeSitter parsers, and formatters for supported languages.

**Supported Languages**:

| Language | LSP Server | TreeSitter | Formatter |
|----------|-----------|------------|-----------|
| Nix | nil_ls / nixd | Yes | alejandra (external) |
| PHP | intelephense | Yes | pint (external) |
| TypeScript/JavaScript | ts_ls | Yes | Built-in |
| Python | pyright | Yes | Built-in |
| Go | gopls | Yes | Built-in |
| Lua | lua_ls | Yes | Built-in |
| Bash | bashls | Yes | Built-in |
| HTML | html | Yes | Built-in |
| CSS | cssls | Yes | Built-in |
| Tailwind | tailwindcss | Yes | N/A |
| Terraform | terraformls | Yes | Built-in |
| HCL | terraformls | Yes | Built-in |
| Markdown | marksman | Yes | Built-in |
| SQL | sqls | Yes | Built-in |
| C/C++ | clangd | Yes | Built-in |
| Zig | zls | Yes | Built-in |
| Nu | Custom | Yes | N/A |

### 5. Custom Plugin Package

Vim plugins built from source that are not in nixpkgs.

**Attributes**:

| Attribute | Type | Description |
|-----------|------|-------------|
| `pname` | String | Plugin name |
| `version` | String | Version string |
| `src` | Derivation | Source (fetchFromGitHub) |
| `buildInputs` | List | Plugin dependencies |

**Instances**:

- laravel.nvim - Laravel development integration
- worktrees.nvim - Git worktree management
- neotest-pest - PHP Pest test adapter
- mcphub.nvim - MCP server hub integration

## File Structure

```text
flakes/nixvim/
├── flake.nix           # Flake definition
├── flake.lock          # Locked dependencies
├── README.md           # Documentation
├── apps.nix            # App outputs definition
├── packages.nix        # Package outputs definition
├── config/
│   ├── default.nix     # Main NixVim configuration
│   └── keybinds.nix    # Keybind definitions
└── pkgs/
    ├── laravel-nvim.nix
    ├── worktrees-nvim.nix
    ├── neotest-pest.nix
    └── mcp-hub.nix
```

## Module Dependencies

```text
flake.nix
├── inputs
│   ├── nixpkgs
│   ├── nixvim
│   ├── flake-parts
│   └── mcphub-nvim
├── packages.nix
│   └── config/
│       ├── default.nix
│       │   ├── keybinds.nix
│       │   └── pkgs/*
│       └── keybinds.nix
└── apps.nix
    └── (uses packages.default)
```

## State Transitions

Not applicable - this is a static configuration that produces an immutable package.

## Validation Rules

1. **Flake builds**: `nix build .#default` must succeed without errors
2. **All LSP servers active**: Each enabled LSP server must attach to appropriate file types
3. **Keybinds functional**: Each defined keymap must execute its action
4. **Plugins load**: All extraPlugins must load without errors on startup
5. **Theme applied**: OneDark darker variant must be active after startup
