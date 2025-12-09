# Research: NixVim Standalone Flake

**Feature Branch**: `003-nixvim-flake`
**Created**: December 8, 2025
**Status**: Complete

## Research Tasks

### 1. NixVim vs nvf Feature Parity

**Question**: Does NixVim provide equivalent functionality to nvf for all required features?

**Decision**: Yes, NixVim provides equivalent or better functionality.

**Rationale**:
- NixVim has native modules for all required plugins (LSP, Telescope, Bufferline, nvim-tree, etc.)
- NixVim uses `plugins.<name>.enable` pattern similar to nvf's module system
- NixVim supports `keymaps` attribute for declarative keybind configuration
- NixVim supports `extraPlugins` for custom/non-module plugins (same as nvf's `lazy.plugins`)
- NixVim supports `extraConfigLua` for custom Lua configuration when needed
- NixVim has built-in support for colorschemes including OneDark via `colorschemes.onedark`

**Alternatives Considered**:
- nixcats-nvim: More flexible but less declarative, requires more Lua knowledge
- Pure Nix wrapper: Too low-level, would require reimplementing plugin management

### 2. NixVim Module Structure for Standalone Flake

**Question**: How to structure a standalone NixVim flake using flake-parts?

**Decision**: Use `makeNixvimWithModule` with flake-parts for consistency with existing flakes.

**Rationale**:
- NixVim provides `makeNixvim` (simple) and `makeNixvimWithModule` (advanced) functions
- `makeNixvimWithModule` allows custom nixpkgs with `config.allowUnfree = true` for intelephense
- flake-parts provides consistent structure with existing hyprland/niri flakes
- Separate configuration into modules (`config/default.nix`, `config/keybinds.nix`) for maintainability

**Implementation Pattern**:
```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim.url = "github:nix-community/nixvim";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = ["x86_64-linux"];
      perSystem = { config, pkgs, system, ... }: {
        packages.default = inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          module = ./config;
        };
      };
    };
}
```

### 3. NixVim LSP Configuration Mapping

**Question**: How do nvf language options map to NixVim LSP configuration?

**Decision**: Use `plugins.lsp.servers.<server>.enable` pattern.

**Mapping Table**:

| nvf Option | NixVim Option | LSP Server |
|------------|---------------|------------|
| `languages.nix.enable` | `plugins.lsp.servers.nil_ls.enable` or `nixd.enable` | nil/nixd |
| `languages.php.enable` | `plugins.lsp.servers.intelephense.enable` | intelephense |
| `languages.ts.enable` | `plugins.lsp.servers.ts_ls.enable` | ts_ls |
| `languages.python.enable` | `plugins.lsp.servers.pyright.enable` | pyright |
| `languages.go.enable` | `plugins.lsp.servers.gopls.enable` | gopls |
| `languages.lua.enable` | `plugins.lsp.servers.lua_ls.enable` | lua-language-server |
| `languages.bash.enable` | `plugins.lsp.servers.bashls.enable` | bash-language-server |
| `languages.html.enable` | `plugins.lsp.servers.html.enable` | vscode-html-language-server |
| `languages.css.enable` | `plugins.lsp.servers.cssls.enable` | vscode-css-language-server |
| `languages.tailwind.enable` | `plugins.lsp.servers.tailwindcss.enable` | tailwindcss-language-server |
| `languages.terraform.enable` | `plugins.lsp.servers.terraformls.enable` | terraform-ls |
| `languages.hcl.enable` | `plugins.lsp.servers.terraformls.enable` | terraform-ls (covers HCL) |
| `languages.markdown.enable` | `plugins.lsp.servers.marksman.enable` | marksman |
| `languages.sql.enable` | `plugins.lsp.servers.sqls.enable` | sqls |
| `languages.clang.enable` | `plugins.lsp.servers.clangd.enable` | clangd |
| `languages.zig.enable` | `plugins.lsp.servers.zls.enable` | zls |
| `languages.nu.enable` | Custom via extraPlugins | nu_lsp (not in nixvim) |

**Note**: Nu language support requires custom plugin setup as it's not in NixVim's default modules.

### 4. Keymaps Configuration

**Question**: How to map nvf keybinds to NixVim format?

**Decision**: Use NixVim's `keymaps` list attribute.

**Mapping Pattern**:
```nix
# nvf format:
keymaps = [{
  key = "<C-s>";
  mode = ["n" "v" "i"];
  action = "<ESC>:w<CR>";
  desc = "Save file";
  silent = true;
  noremap = true;
}];

# NixVim format (identical!):
keymaps = [{
  key = "<C-s>";
  mode = ["n" "v" "i"];
  action = "<cmd>w<CR>";  # Prefer <cmd> over :
  options = {
    desc = "Save file";
    silent = true;
    noremap = true;
  };
}];
```

**Key Differences**:
- NixVim uses `options = { ... }` subattribute for silent, noremap, desc
- NixVim prefers `<cmd>...<CR>` over `<ESC>:...<CR>` for Ex commands
- For Lua functions, use `action.__raw = "function() ... end"`

### 5. Plugin Module Mapping

**Question**: How do nvf plugin options map to NixVim?

**Decision**: Most plugins have direct NixVim equivalents.

**Mapping Table**:

| nvf Plugin | NixVim Module | Notes |
|------------|--------------|-------|
| `telescope.enable` | `plugins.telescope.enable` | Direct |
| `treesitter.*` | `plugins.treesitter.*` | Direct |
| `autocomplete.nvim-cmp.enable` | `plugins.cmp.enable` | Direct |
| `dashboard.alpha.enable` | `plugins.alpha.enable` | Direct |
| `autopairs.nvim-autopairs.enable` | `plugins.nvim-autopairs.enable` | Direct |
| `statusline.lualine.enable` | `plugins.lualine.enable` | Direct |
| `tabline.nvimBufferline.enable` | `plugins.bufferline.enable` | Direct |
| `comments.comment-nvim.enable` | `plugins.comment.enable` | Different name |
| `filetree.nvimTree.enable` | `plugins.nvim-tree.enable` | Direct |
| `git.gitsigns.enable` | `plugins.gitsigns.enable` | Direct |
| `terminal.toggleterm.enable` | `plugins.toggleterm.enable` | Direct |
| `binds.whichKey.enable` | `plugins.which-key.enable` | Direct |
| `utility.surround.enable` | `plugins.nvim-surround.enable` | Direct |
| `utility.motion.leap.enable` | `plugins.leap.enable` | Direct |
| `debugger.nvim-dap.*` | `plugins.dap.*` | Direct |
| `assistant.copilot.enable` | `plugins.copilot-lua.enable` | Direct |
| `notify.nvim-notify.enable` | `plugins.notify.enable` | Direct |

### 6. Custom Plugins Integration

**Question**: How to integrate custom plugins (laravel.nvim, worktrees.nvim, etc.)?

**Decision**: Use `extraPlugins` with `vimUtils.buildVimPlugin` and `extraConfigLua` for setup.

**Implementation Pattern**:
```nix
{
  extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      pname = "laravel.nvim";
      version = "3.2.1";
      src = pkgs.fetchFromGitHub {
        owner = "adalessa";
        repo = "laravel.nvim";
        rev = "v3.2.1";
        sha256 = "sha256-...";
      };
    })
  ];

  extraConfigLua = ''
    require('laravel').setup({
      lsp_server = "intelephense",
    })
  '';
}
```

**Note**: Can reuse the same package definitions from the nvf flake's `pkgs/` directory.

### 7. OneDark Theme with Transparency

**Question**: How to configure OneDark darker variant with transparency?

**Decision**: Use `colorschemes.onedark` module.

**Implementation**:
```nix
{
  colorschemes.onedark = {
    enable = true;
    settings = {
      style = "darker";
      transparent = true;
    };
  };
}
```

### 8. Avante.nvim with MCPHub Integration

**Question**: How to configure Avante with MCPHub in NixVim?

**Decision**: Use `plugins.avante` module with custom Lua configuration.

**Challenge**: MCPHub integration requires dynamic Lua code that accesses the mcphub instance at runtime.

**Implementation**:
```nix
{
  plugins.avante = {
    enable = true;
    settings = {
      provider = "copilot";
      # Other settings...
    };
  };

  # MCPHub custom tools require raw Lua - unavoidable
  extraConfigLua = ''
    -- Override avante's system_prompt and custom_tools after setup
    local avante_config = require('avante.config')
    avante_config.override({
      system_prompt = function()
        local hub = require("mcphub").get_hub_instance()
        return hub and hub:get_active_servers_prompt() or ""
      end,
      custom_tools = function()
        return {
          require("mcphub.extensions.avante").mcp_tool(),
        }
      end,
    })
  '';
}
```

**Note**: Some Lua is unavoidable for dynamic MCPHub integration.

## Technology Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Flake structure | flake-parts | Consistency with existing flakes |
| NixVim build function | `makeNixvimWithModule` | Custom nixpkgs for unfree packages |
| Config organization | Separate modules (`config/`) | Maintainability, parity with nvf |
| LSP configuration | Native `plugins.lsp.servers` | Declarative, no raw Lua needed |
| Keymaps | Native `keymaps` attribute | Declarative, nearly identical to nvf |
| Custom plugins | `extraPlugins` + reuse pkgs | DRY principle |
| Theme | `colorschemes.onedark` | Native module available |
| Raw Lua usage | Minimal (MCPHub only) | User requirement to avoid Lua |

## Unresolved Items

None - all research questions answered.
