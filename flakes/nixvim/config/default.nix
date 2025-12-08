{
  pkgs,
  lib,
  laravel-nvim,
  worktrees-nvim,
  neotest-pest,
  mcphub-nvim,
  mcp-hub,
  ...
}: {
  # Import keybinds module
  imports = [
    ./keybinds.nix
  ];

  # Core Neovim options
  opts = {
    number = true;
    relativenumber = true;
    shiftwidth = 4;
    tabstop = 4;
    expandtab = true;
    smartindent = true;
    wrap = false;
    swapfile = false;
    backup = false;
    undofile = true;
    hlsearch = false;
    incsearch = true;
    termguicolors = true;
    scrolloff = 8;
    signcolumn = "yes";
    updatetime = 50;
    colorcolumn = "80";
    mouse = "a";
    clipboard = "unnamedplus";
    cursorline = true;
    splitbelow = true;
    splitright = true;
  };

  # Global settings
  globals = {
    mapleader = " ";
    maplocalleader = " ";
  };

  # Colorscheme - OneDark darker with transparency
  colorschemes.onedark = {
    enable = true;
    settings = {
      style = "darker";
      transparent = true;
      term_colors = true;
      ending_tildes = false;
      cmp_itemkind_reverse = false;
      code_style = {
        comments = "italic";
        keywords = "none";
        functions = "none";
        strings = "none";
        variables = "none";
      };
      lualine = {
        transparent = true;
      };
      diagnostics = {
        darker = true;
        undercurl = true;
        background = true;
      };
    };
  };

  # TreeSitter
  plugins.treesitter = {
    enable = true;
    settings = {
      auto_install = true;
      ensure_installed = [
        "bash"
        "c"
        "cpp"
        "css"
        "dockerfile"
        "go"
        "hcl"
        "html"
        "javascript"
        "json"
        "lua"
        "markdown"
        "markdown_inline"
        "nix"
        "php"
        "python"
        "rust"
        "sql"
        "terraform"
        "tsx"
        "typescript"
        "vim"
        "vimdoc"
        "yaml"
        "zig"
      ];
      highlight = {
        enable = true;
        additional_vim_regex_highlighting = false;
      };
      indent = {
        enable = true;
      };
    };
  };

  plugins.treesitter-context = {
    enable = true;
  };

  # LSP Configuration
  plugins.lsp = {
    enable = true;

    servers = {
      # Nix
      nil_ls = {
        enable = true;
        settings = {
          formatting.command = ["alejandra"];
        };
      };

      # PHP
      intelephense = {
        enable = true;
        package = pkgs.nodePackages.intelephense;
        settings = {
          intelephense = {
            files.maxSize = 5000000;
          };
        };
      };

      # TypeScript/JavaScript
      ts_ls = {
        enable = true;
      };

      # Python
      pyright = {
        enable = true;
      };

      # Go
      gopls = {
        enable = true;
      };

      # Lua
      lua_ls = {
        enable = true;
        settings = {
          Lua = {
            diagnostics = {
              globals = ["vim"];
            };
            workspace = {
              checkThirdParty = false;
            };
            telemetry.enable = false;
          };
        };
      };

      # Bash
      bashls = {
        enable = true;
      };

      # HTML
      html = {
        enable = true;
      };

      # CSS
      cssls = {
        enable = true;
      };

      # Tailwind CSS
      tailwindcss = {
        enable = true;
      };

      # Terraform/HCL
      terraformls = {
        enable = true;
      };

      # Markdown
      marksman = {
        enable = true;
      };

      # SQL
      sqls = {
        enable = true;
      };

      # C/C++
      clangd = {
        enable = true;
      };

      # Zig
      zls = {
        enable = true;
      };
    };

    keymaps = {
      lspBuf = {
        K = "hover";
        gD = "declaration";
        gd = "definition";
        gi = "implementation";
        gr = "references";
        gt = "type_definition";
        "<leader>ca" = "code_action";
        "<leader>rn" = "rename";
      };
      diagnostic = {
        "<leader>e" = "open_float";
        "[d" = "goto_prev";
        "]d" = "goto_next";
      };
    };
  };

  # Telescope
  plugins.telescope = {
    enable = true;
    settings = {
      defaults = {
        file_ignore_patterns = [
          "node_modules"
          ".git/"
          "vendor/"
        ];
        layout_config = {
          horizontal = {
            preview_width = 0.55;
          };
        };
      };
      pickers = {
        find_files = {
          hidden = true;
          no_ignore = false;
        };
      };
    };
    extensions = {
      fzf-native.enable = true;
    };
    keymaps = {
      "<leader>ff" = "find_files";
      "<leader>fg" = "live_grep";
      "<leader>fb" = "buffers";
      "<leader>fh" = "help_tags";
      "<leader>fr" = "oldfiles";
      "<leader>fc" = "commands";
      "<leader>fd" = "diagnostics";
    };
  };

  # Bufferline
  plugins.bufferline = {
    enable = true;
    settings = {
      options = {
        mode = "buffers";
        diagnostics = "nvim_lsp";
        separator_style = "slant";
        show_buffer_close_icons = true;
        show_close_icon = false;
        always_show_bufferline = true;
        offsets = [
          {
            filetype = "NvimTree";
            text = "File Explorer";
            highlight = "Directory";
            separator = true;
          }
        ];
      };
    };
  };

  # NvimTree
  plugins.nvim-tree = {
    enable = true;
    settings = {
      git = {
        enable = true;
        ignore = false;
      };
      modified = {
        enable = true;
      };
      hijack_cursor = true;
      renderer = {
        highlight_opened_files = "all";
      };
      view = {
        cursorline = true;
        width = 35;
      };
    };
  };

  # Lualine
  plugins.lualine = {
    enable = true;
    settings = {
      options = {
        theme = "onedark";
        globalstatus = true;
        component_separators = {
          left = "|";
          right = "|";
        };
        section_separators = {
          left = "";
          right = "";
        };
      };
      sections = {
        lualine_a = ["mode"];
        lualine_b = ["branch" "diff" "diagnostics"];
        lualine_c = ["filename"];
        lualine_x = ["encoding" "fileformat" "filetype"];
        lualine_y = ["progress"];
        lualine_z = ["location"];
      };
    };
  };

  # Alpha dashboard
  plugins.alpha = {
    enable = true;
    theme = "dashboard";
  };

  # Which-key
  plugins.which-key = {
    enable = true;
    settings = {
      preset = "helix";
    };
  };

  # Notify
  plugins.notify = {
    enable = true;
    settings = {
      background_colour = "#000000";
      render = "compact";
      stages = "fade";
      timeout = 3000;
    };
  };

  # Comment
  plugins.comment = {
    enable = true;
  };

  # Autopairs
  plugins.nvim-autopairs = {
    enable = true;
  };

  # Leap (motion)
  plugins.leap = {
    enable = true;
  };

  # Surround
  plugins.nvim-surround = {
    enable = true;
  };

  # Gitsigns
  plugins.gitsigns = {
    enable = true;
    settings = {
      current_line_blame = false;
      signs = {
        add = {text = "│";};
        change = {text = "│";};
        delete = {text = "_";};
        topdelete = {text = "‾";};
        changedelete = {text = "~";};
      };
    };
  };

  # Fugitive
  plugins.fugitive = {
    enable = true;
  };

  # Git conflict
  plugins.git-conflict = {
    enable = true;
  };

  # Gitlinker
  plugins.gitlinker = {
    enable = true;
  };

  # nvim-cmp (completion)
  plugins.cmp = {
    enable = true;
    autoEnableSources = true;
    settings = {
      sources = [
        {name = "nvim_lsp";}
        {name = "path";}
        {name = "buffer";}
        {name = "luasnip";}
        {name = "copilot";}
      ];
      mapping = {
        "<C-Space>" = "cmp.mapping.complete()";
        "<C-e>" = "cmp.mapping.close()";
        "<CR>" = "cmp.mapping.confirm({ select = true })";
        "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
        "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
        "<C-d>" = "cmp.mapping.scroll_docs(-4)";
        "<C-f>" = "cmp.mapping.scroll_docs(4)";
      };
      snippet = {
        expand = "function(args) require('luasnip').lsp_expand(args.body) end";
      };
    };
  };

  # LuaSnip
  plugins.luasnip = {
    enable = true;
  };

  # Copilot
  plugins.copilot-lua = {
    enable = true;
    settings = {
      suggestion = {
        enabled = false;
      };
      panel = {
        enabled = false;
      };
    };
  };

  # Avante (AI assistant)
  plugins.avante = {
    enable = true;
    settings = {
      provider = "copilot";
      cursor_applying_provider = "copilot";
      auto_suggestions_provider = "copilot";
      behaviour = {
        auto_suggestions = false;
      };
    };
  };

  # DAP (debugging)
  plugins.dap = {
    enable = true;
  };

  # DAP UI
  plugins.dap-ui.enable = true;

  # DAP Virtual Text
  plugins.dap-virtual-text.enable = true;

  # Toggleterm
  plugins.toggleterm = {
    enable = true;
    settings = {
      direction = "float";
      float_opts = {
        border = "curved";
      };
      open_mapping = "[[<C-\\>]]";
    };
  };

  # Indent blankline
  plugins.indent-blankline = {
    enable = true;
  };

  # Web devicons
  plugins.web-devicons = {
    enable = true;
  };

  # Illuminate (highlight word under cursor)
  plugins.illuminate = {
    enable = true;
  };

  # Colorizer (color preview)
  plugins.colorizer = {
    enable = true;
  };

  # Trouble (diagnostics list)
  plugins.trouble = {
    enable = true;
  };

  # Custom plugins via extraPlugins
  extraPlugins = with pkgs.vimPlugins; [
    # Laravel
    laravel-nvim

    # Worktrees
    worktrees-nvim

    # Neotest with Pest adapter
    neotest
    neotest-pest

    # MCPHub
    mcphub-nvim

    # Dependencies
    plenary-nvim
    nui-nvim
    promise-async
    vim-dotenv
    snacks-nvim
  ];

  # Extra packages (CLI tools)
  extraPackages = with pkgs; [
    # MCP Hub CLI
    mcp-hub

    # Formatters
    alejandra
    nodePackages.prettier
    stylua

    # LSP extras
    ripgrep
    fd
    lazygit
  ];

  # Lua configuration for custom plugins
  extraConfigLua = ''
    -- Laravel setup
    require('laravel').setup({
      lsp_server = "intelephense",
    })

    -- Worktrees setup
    require('worktrees').setup({})

    -- Register worktrees telescope extension
    pcall(function()
      require('telescope').load_extension('worktrees')
    end)

    -- Neotest setup with Pest adapter
    require('neotest').setup({
      adapters = {
        require('neotest-pest'),
      },
    })

    -- MCPHub setup
    require('mcphub').setup({
      workspace = {
        enabled = true,
        look_for = {".mcphub/servers.json", ".vscode/mcp.json", ".cursor/mcp.json"},
        reload_on_dir_changed = true,
        port_range = {
          min = 40000,
          max = 41000,
        },
      },
      extensions = {
        avante = {
          make_slash_commands = true,
        },
      },
    })

    -- Override Avante config for MCPHub integration
    pcall(function()
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
    end)

    -- Snacks.nvim setup for lazygit
    require('snacks').setup({
      lazygit = { configure = true },
    })
  '';
}
