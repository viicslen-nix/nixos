# Keybind configuration for NixVim
# Mirrors the keybinds from the nvf flake configuration
{
  keymaps = [
    # File operations
    {
      key = "<C-s>";
      mode = ["n" "v" "i"];
      action = "<cmd>w<CR>";
      options = {
        desc = "Save file";
        silent = true;
        noremap = true;
      };
    }

    # Append characters
    {
      key = "<leader>;";
      mode = ["n"];
      action = "<S-a>;<ESC>";
      options = {
        desc = "Insert semicolon";
        noremap = true;
      };
    }
    {
      key = "<leader>,";
      mode = ["n"];
      action = "<S-a>,<ESC>";
      options = {
        desc = "Insert comma";
        noremap = true;
      };
    }

    # Visual mode indentation
    {
      key = ">";
      mode = ["v"];
      action = ">gv";
      options = {
        desc = "Indent selection";
        noremap = true;
      };
    }
    {
      key = "<";
      mode = ["v"];
      action = "<gv";
      options = {
        desc = "Unindent selection";
        noremap = true;
      };
    }

    # Buffer navigation
    {
      key = "<Tab>";
      mode = ["n"];
      action = "<cmd>BufferLineCycleNext<CR>";
      options = {
        desc = "Next buffer";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<S-Tab>";
      mode = ["n"];
      action = "<cmd>BufferLineCyclePrev<CR>";
      options = {
        desc = "Previous buffer";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>x";
      mode = ["n"];
      action = "<cmd>bdelete<CR>";
      options = {
        desc = "Close buffer";
        silent = true;
        noremap = true;
      };
    }

    # LSP keybinds (additional to plugins.lsp.keymaps)
    {
      key = "<leader>gD";
      mode = ["n"];
      action = "<cmd>lua vim.lsp.buf.declaration()<CR>";
      options = {
        desc = "Go to declaration";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>gd";
      mode = ["n"];
      action = "<cmd>lua vim.lsp.buf.definition()<CR>";
      options = {
        desc = "Go to definition";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>gt";
      mode = ["n"];
      action = "<cmd>lua vim.lsp.buf.type_definition()<CR>";
      options = {
        desc = "Go to type definition";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>h";
      mode = ["n"];
      action = "<cmd>lua vim.lsp.buf.hover()<CR>";
      options = {
        desc = "Hover documentation";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>gi";
      mode = ["n"];
      action = "<cmd>lua vim.lsp.buf.implementation()<CR>";
      options = {
        desc = "List implementations";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>gr";
      mode = ["n"];
      action = "<cmd>lua vim.lsp.buf.references()<CR>";
      options = {
        desc = "List references";
        silent = true;
        noremap = true;
      };
    }

    # Comment toggle
    {
      key = "<C-/>";
      mode = ["n"];
      action = "gcc";
      options = {
        desc = "Toggle comment";
        remap = true;
      };
    }
    {
      key = "<C-/>";
      mode = ["v"];
      action = "gc";
      options = {
        desc = "Toggle comment selection";
        remap = true;
      };
    }

    # NvimTree
    {
      key = "<leader>e";
      mode = ["n"];
      action = "<cmd>NvimTreeToggle<CR>";
      options = {
        desc = "Toggle file tree";
        silent = true;
        noremap = true;
      };
    }

    # Laravel keybinds
    {
      key = "<leader>lla";
      mode = ["n"];
      action = "<cmd>Laravel artisan<CR>";
      options = {
        desc = "Laravel Artisan";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>llr";
      mode = ["n"];
      action = "<cmd>Laravel routes<CR>";
      options = {
        desc = "Laravel Routes";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>llm";
      mode = ["n"];
      action = "<cmd>Laravel related<CR>";
      options = {
        desc = "Laravel Related";
        silent = true;
        noremap = true;
      };
    }

    # Worktrees keybinds
    {
      key = "<leader>gws";
      mode = ["n"];
      action.__raw = ''
        function()
          require("telescope").extensions.worktrees.list_worktrees()
        end
      '';
      options = {
        desc = "Worktrees picker";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>gwc";
      mode = ["n"];
      action = "<cmd>GitWorktreeCreate<CR>";
      options = {
        desc = "New worktree";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>gwa";
      mode = ["n"];
      action = "<cmd>GitWorktreeCreateExisting<CR>";
      options = {
        desc = "Worktree for existing branch";
        silent = true;
        noremap = true;
      };
    }

    # Git
    {
      key = "<leader>gg";
      mode = ["n"];
      action.__raw = ''
        function()
          Snacks.lazygit()
        end
      '';
      options = {
        desc = "Open Lazygit";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>gs";
      mode = ["n"];
      action = "<cmd>Git<CR>";
      options = {
        desc = "Git status (Fugitive)";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>gl";
      mode = ["n"];
      action = "<cmd>GitLinker<CR>";
      options = {
        desc = "Copy git link";
        silent = true;
        noremap = true;
      };
    }

    # Neotest
    {
      key = "<leader>tt";
      mode = ["n"];
      action.__raw = ''
        function()
          require("neotest").run.run()
        end
      '';
      options = {
        desc = "Run nearest test";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>tf";
      mode = ["n"];
      action.__raw = ''
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end
      '';
      options = {
        desc = "Run file tests";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>to";
      mode = ["n"];
      action.__raw = ''
        function()
          require("neotest").output_panel.toggle()
        end
      '';
      options = {
        desc = "Toggle test output";
        silent = true;
        noremap = true;
      };
    }

    # DAP (debugging)
    {
      key = "<leader>db";
      mode = ["n"];
      action.__raw = ''
        function()
          require("dap").toggle_breakpoint()
        end
      '';
      options = {
        desc = "Toggle breakpoint";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>dc";
      mode = ["n"];
      action.__raw = ''
        function()
          require("dap").continue()
        end
      '';
      options = {
        desc = "Continue/Start debugging";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>di";
      mode = ["n"];
      action.__raw = ''
        function()
          require("dap").step_into()
        end
      '';
      options = {
        desc = "Step into";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>do";
      mode = ["n"];
      action.__raw = ''
        function()
          require("dap").step_over()
        end
      '';
      options = {
        desc = "Step over";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>du";
      mode = ["n"];
      action.__raw = ''
        function()
          require("dapui").toggle()
        end
      '';
      options = {
        desc = "Toggle DAP UI";
        silent = true;
        noremap = true;
      };
    }

    # Trouble
    {
      key = "<leader>xx";
      mode = ["n"];
      action = "<cmd>TroubleToggle<CR>";
      options = {
        desc = "Toggle diagnostics";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>xw";
      mode = ["n"];
      action = "<cmd>TroubleToggle workspace_diagnostics<CR>";
      options = {
        desc = "Workspace diagnostics";
        silent = true;
        noremap = true;
      };
    }
    {
      key = "<leader>xd";
      mode = ["n"];
      action = "<cmd>TroubleToggle document_diagnostics<CR>";
      options = {
        desc = "Document diagnostics";
        silent = true;
        noremap = true;
      };
    }

    # Window navigation
    {
      key = "<C-h>";
      mode = ["n"];
      action = "<C-w>h";
      options = {
        desc = "Move to left window";
        noremap = true;
      };
    }
    {
      key = "<C-j>";
      mode = ["n"];
      action = "<C-w>j";
      options = {
        desc = "Move to bottom window";
        noremap = true;
      };
    }
    {
      key = "<C-k>";
      mode = ["n"];
      action = "<C-w>k";
      options = {
        desc = "Move to top window";
        noremap = true;
      };
    }
    {
      key = "<C-l>";
      mode = ["n"];
      action = "<C-w>l";
      options = {
        desc = "Move to right window";
        noremap = true;
      };
    }

    # Better escape
    {
      key = "jk";
      mode = ["i"];
      action = "<ESC>";
      options = {
        desc = "Exit insert mode";
        noremap = true;
      };
    }

    # Clear search highlight
    {
      key = "<ESC>";
      mode = ["n"];
      action = "<cmd>noh<CR>";
      options = {
        desc = "Clear search highlight";
        silent = true;
        noremap = true;
      };
    }
  ];
}
