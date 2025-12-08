# NixVim Neovim Configuration

A standalone Neovim configuration using the NixVim framework, providing feature parity with the nvf-based configuration.

## Features

- **Full LSP Support**: 17 language servers including Nix, PHP (Intelephense), TypeScript, Python, Go, Lua, Bash, HTML, CSS, Tailwind, Terraform, HCL, Markdown, SQL, C/C++, and Zig
- **TreeSitter**: Syntax highlighting and code folding for all supported languages
- **OneDark Theme**: Darker variant with transparency support
- **Productivity Plugins**: Telescope, nvim-tree, bufferline, lualine, alpha dashboard, which-key
- **Git Integration**: Gitsigns, vim-fugitive, git-conflict, gitlinker, worktrees.nvim
- **AI Assistance**: GitHub Copilot, Avante with MCPHub integration
- **Custom Plugins**: laravel.nvim, worktrees.nvim, neotest-pest, mcphub.nvim

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

## Directory Structure

```text
flakes/nixvim/
├── flake.nix           # Flake definition with inputs and outputs
├── flake.lock          # Locked dependency versions
├── README.md           # This file
├── apps.nix            # App output definitions
├── packages.nix        # Package output definitions
├── config/
│   ├── default.nix     # Main NixVim configuration
│   └── keybinds.nix    # Keybind definitions
└── pkgs/
    ├── laravel-nvim.nix    # Laravel.nvim plugin
    ├── worktrees-nvim.nix  # Worktrees.nvim plugin
    ├── neotest-pest.nix    # Neotest Pest adapter
    └── mcp-hub.nix         # MCPHub plugin and CLI
```

## Key Bindings

| Key | Mode | Action |
|-----|------|--------|
| `<C-s>` | n, v, i | Save file |
| `<leader>gd` | n | Go to definition |
| `<leader>gD` | n | Go to declaration |
| `<leader>gr` | n | List references |
| `<leader>gi` | n | List implementations |
| `<leader>h` | n | Hover documentation |
| `<Tab>` | n | Next buffer |
| `<S-Tab>` | n | Previous buffer |
| `<leader>x` | n | Close buffer |
| `<C-/>` | n, v | Toggle comment |
| `<leader>;` | n | Append semicolon |
| `<leader>,` | n | Append comma |
| `<leader>lla` | n | Laravel artisan |
| `<leader>llr` | n | Laravel routes |
| `<leader>llm` | n | Laravel related files |
| `<leader>gws` | n | Git worktrees picker |
| `<leader>gwc` | n | Create new worktree |

## Verification

### Check LSP Status

```vim
:LspInfo
```

### Check Loaded Plugins

```vim
:Lazy
```

### Check Keybinds

Press `<leader>` and wait for which-key popup.

## Comparison with nvf

This configuration is designed to be feature-equivalent with the nvf-based Neovim configuration in `flakes/neovim/`. The main differences are:

1. **Framework**: Uses NixVim instead of nvf
2. **Configuration Style**: NixVim module options instead of nvf's vim.* options
3. **Plugin Loading**: Uses NixVim's native plugin modules where available

## License

Same as the parent repository.
