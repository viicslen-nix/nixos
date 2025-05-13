{
  programs.nvf.settings.vim = {
    keymaps = [
      {
        key = "<C-s>";
        mode = ["n" "v" "i"];
        action = "<ESC>:w<CR>";
        desc = "Save file";
        silent = true;
        unique = false;
        noremap = true;
      }
    ];

    lsp.mappings = {
      goToDeclaration = "<leader>gD";
      goToDefinition = "<leader>gd";
      goToType = "<leader>gt";
      hover = "<leader>h";
      listImplementations = "<leader>gi";
      listReferences = "<leader>gr";
    };

    tabline.nvimBufferline.mappings = {
      closeCurrent = "<leader>x";
      cycleNext = "<Tab>";
      cyclePrevious = "<S-Tab>";
    };

    assistant.copilot.mappings = {
      suggestion.acceptLine = "<M-L>";
    };

    comments.comment-nvim.mappings = {
      toggleCurrentLine = "<C-/>";
      toggleCurrentBlock = "<C-?>";
      toggleOpLeaderLine = "/";
      toggleOpLeaderBlock = "?";
      toggleSelectedLine = "<C-/>";
      toggleSelectedBlock = "<C-?>";
    };

    lazy.plugins = {
      "laravel.nvim".keys = [
        {
          key = "<leader>laa";
          action = ":Laravel artisan<cr>";
          mode = "n";
        }
        {
          key = "<leader>lar";
          action = ":Laravel routes<cr>";
          mode = "n";
        }
        {
          key = "<leader>lam";
          action = ":Laravel related<cr>";
          mode = "n";
        }
        {
          key = "gf";
          action = ''
            function()
              if require("laravel").app("gf").cursor_on_resource() then
                return "<cmd>Laravel gf<CR>"
              else
                return "gf"
              end
            end
          '';
          lua = true;
          noremap = false;
          expr = true;
          mode = "n";
        }
      ];
    };
  };
}
