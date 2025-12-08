# Quickstart Guide: NixVim Standalone Flake

**Feature Branch**: `003-nixvim-flake`
**Created**: December 8, 2025

## Prerequisites

- Nix with flakes enabled
- x86_64-linux system
- Network access for initial build

## Quick Start

### Build and Run

```bash
# Navigate to the flake directory
cd flakes/nixvim

# Build the Neovim package
nix build .#default

# Run Neovim directly
nix run .#default

# Or run the built result
./result/bin/nvim
```

### Development Shell

```bash
# Enter the development shell
nix develop

# This provides:
# - nix-output-monitor (nom) for better build output
# - alejandra for Nix formatting
```

### Build with Enhanced Output

```bash
# Use nix-output-monitor for better build visibility
nom build .#default
```

## Verify Installation

### Check LSP Servers

Open a file of each type and verify LSP is attached:

```vim
:LspInfo
```

Expected: Shows active LSP server for the file type

### Check Keybinds

Press `<leader>` and wait for which-key popup to verify keybind configuration.

Key test cases:

- `Ctrl+s` in any mode → saves file
- `<leader>gd` → go to definition
- `Tab` → next buffer
- `<leader>gws` → worktree picker

### Check Theme

Visual verification:

- OneDark darker variant applied
- Background is transparent (if terminal supports it)

### Check Plugins

```vim
:Lazy
```

Expected: Shows all loaded plugins without errors

## Directory Structure

```text
flakes/nixvim/
├── flake.nix           # Entry point
├── flake.lock          # Dependency lock
├── README.md           # This project's README
├── apps.nix            # App definitions
├── packages.nix        # Package definitions
├── config/
│   ├── default.nix     # Main config
│   └── keybinds.nix    # Keybind config
└── pkgs/
    └── *.nix           # Custom plugin packages
```

## Common Tasks

### Update Dependencies

```bash
nix flake update
```

### Format Nix Files

```bash
nix develop -c alejandra .
```

### Check Configuration

```bash
nix flake check
```

### Add New Plugin

1. If plugin has NixVim module:

```nix
# In config/default.nix
plugins.<plugin-name>.enable = true;
```

2. If plugin needs custom package:

```nix
# In pkgs/<plugin>.nix
{ pkgs }:
pkgs.vimUtils.buildVimPlugin {
  pname = "plugin-name";
  version = "x.y.z";
  src = pkgs.fetchFromGitHub { ... };
}

# In config/default.nix
extraPlugins = [ pkgs.callPackage ../pkgs/<plugin>.nix {} ];
```

### Add New Keybind

```nix
# In config/keybinds.nix
keymaps = [
  # ... existing keymaps
  {
    key = "<leader>xx";
    action = "<cmd>SomeCommand<CR>";
    mode = "n";
    options.desc = "Description";
  }
];
```

## Troubleshooting

### Build Fails with Unfree Package Error

The flake configures its own nixpkgs with `allowUnfree = true`. If you still see errors:

```bash
export NIXPKGS_ALLOW_UNFREE=1
nix build --impure .#default
```

### LSP Server Not Found

Check that the server package is installed:

```bash
nix build .#default
./result/bin/nvim --headless -c "lua print(vim.inspect(vim.lsp.get_active_clients()))" -c "q"
```

### Plugin Not Loading

Check `:messages` for startup errors:

```vim
:messages
```

### Theme Not Applied

Verify colorscheme is set:

```vim
:colorscheme
```

Expected output: `onedark`
