# Flake Interface Contract

**Feature Branch**: `003-nixvim-flake`
**Created**: December 8, 2025

## Flake Inputs

```nix
{
  inputs = {
    # Required: NixOS packages
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-unstable";
    };

    # Required: Flake composition
    flake-parts = {
      type = "github";
      owner = "hercules-ci";
      repo = "flake-parts";
    };

    # Required: NixVim framework
    nixvim = {
      type = "github";
      owner = "nix-community";
      repo = "nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Required: MCPHub plugin source
    mcphub-nvim = {
      type = "github";
      owner = "ravitemer";
      repo = "mcphub.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

## Flake Outputs

### packages

| Output | Type | Description |
|--------|------|-------------|
| `packages.x86_64-linux.default` | Derivation | Complete Neovim package with all plugins and configuration |
| `packages.x86_64-linux.mcphub-nvim` | Derivation | MCPHub plugin package |
| `packages.x86_64-linux.mcp-hub` | Derivation | MCP Hub CLI tool |
| `packages.x86_64-linux.laravel-nvim` | Derivation | Laravel.nvim plugin package |
| `packages.x86_64-linux.neotest-pest` | Derivation | Neotest Pest adapter package |
| `packages.x86_64-linux.worktrees-nvim` | Derivation | Worktrees.nvim plugin package |

### apps

| Output | Type | Description |
|--------|------|-------------|
| `apps.x86_64-linux.default` | App | Runnable Neovim application |

### devShells

| Output | Type | Description |
|--------|------|-------------|
| `devShells.x86_64-linux.default` | DevShell | Development shell with nix-output-monitor and alejandra |

### checks

| Output | Type | Description |
|--------|------|-------------|
| `checks.x86_64-linux.nix-fmt` | Derivation | Nix formatting check |

## NixVim Configuration Contract

### Required Options

```nix
{
  # Core Neovim options
  opts = {
    shiftwidth = <int>;   # Tab width (default: 4)
    tabstop = <int>;      # Tab stop (default: 4)
  };

  # Theme
  colorschemes.onedark = {
    enable = true;
    settings.style = "darker";
    settings.transparent = true;
  };

  # LSP (all must be enabled)
  plugins.lsp = {
    enable = true;
    servers = {
      nil_ls.enable = true;      # Nix
      intelephense.enable = true; # PHP
      ts_ls.enable = true;        # TypeScript
      pyright.enable = true;      # Python
      gopls.enable = true;        # Go
      lua_ls.enable = true;       # Lua
      bashls.enable = true;       # Bash
      html.enable = true;         # HTML
      cssls.enable = true;        # CSS
      tailwindcss.enable = true;  # Tailwind
      terraformls.enable = true;  # Terraform/HCL
      marksman.enable = true;     # Markdown
      sqls.enable = true;         # SQL
      clangd.enable = true;       # C/C++
      zls.enable = true;          # Zig
    };
  };

  # TreeSitter
  plugins.treesitter = {
    enable = true;
    settings.indent.enable = true;
    # Grammars auto-installed based on enabled languages
  };

  # UI Plugins
  plugins.telescope.enable = true;
  plugins.bufferline.enable = true;
  plugins.nvim-tree.enable = true;
  plugins.lualine.enable = true;
  plugins.alpha.enable = true;
  plugins.which-key.enable = true;
  plugins.notify.enable = true;

  # Productivity Plugins
  plugins.comment.enable = true;
  plugins.nvim-autopairs.enable = true;
  plugins.leap.enable = true;
  plugins.nvim-surround.enable = true;

  # Git Plugins
  plugins.gitsigns.enable = true;
  plugins.fugitive.enable = true;
  plugins.gitlinker.enable = true;

  # Completion
  plugins.cmp.enable = true;
  plugins.copilot-lua.enable = true;

  # Debugging
  plugins.dap.enable = true;

  # Terminal
  plugins.toggleterm.enable = true;

  # AI Assistant
  plugins.avante.enable = true;
}
```

### Required Keymaps

| Key | Mode | Action | Description |
|-----|------|--------|-------------|
| `<C-s>` | n, v, i | Save file | Save current buffer |
| `<leader>gD` | n | Go to declaration | LSP declaration |
| `<leader>gd` | n | Go to definition | LSP definition |
| `<leader>gt` | n | Go to type | LSP type definition |
| `<leader>h` | n | Hover | LSP hover info |
| `<leader>gi` | n | List implementations | LSP implementations |
| `<leader>gr` | n | List references | LSP references |
| `<leader>x` | n | Close buffer | Close current buffer |
| `<Tab>` | n | Next buffer | Cycle to next buffer |
| `<S-Tab>` | n | Previous buffer | Cycle to previous buffer |
| `<C-/>` | n, v | Toggle comment | Comment/uncomment |
| `<leader>;` | n | Append semicolon | Add ; to line end |
| `<leader>,` | n | Append comma | Add , to line end |
| `>` | v | Indent | Indent selection |
| `<` | v | Unindent | Unindent selection |
| `<leader>lla` | n | Laravel artisan | Open artisan picker |
| `<leader>llr` | n | Laravel routes | Show routes |
| `<leader>llm` | n | Laravel related | Show related files |
| `<leader>gws` | n | Worktrees | Open worktree picker |
| `<leader>gwc` | n | New worktree | Create worktree |
| `<leader>gwa` | n | Worktree existing | Create for existing branch |

### Required Custom Plugins

| Plugin | Source | Version | Setup Required |
|--------|--------|---------|----------------|
| laravel.nvim | adalessa/laravel.nvim | v3.2.1 | Yes |
| worktrees.nvim | Juksuu/worktrees.nvim | dev | Yes |
| neotest-pest | V13Axel/neotest-pest | v1.0 | Yes |
| mcphub.nvim | ravitemer/mcphub.nvim | latest | Yes |
| mcp-hub (CLI) | ravitemer/mcp-hub | v4.2.0 | N/A (extraPackages) |
