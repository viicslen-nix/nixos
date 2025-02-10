{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; let
  name = "nvf";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  config = mkIf cfg.enable {
    programs.nvf = {
      enable = true;

      settings = {
        vim = {
          viAlias = true;
          vimAlias = true;
          hideSearchHighlight = true;
          syntaxHighlighting = true;
          useSystemClipboard = true;
          undoFile.enable = true;
          withNodeJs = true;

          options = {
            shiftwidth = 4;
            tabstop = 4;
          };

          spellcheck = {
            enable = false;
            languages = ["en" "es"];
          };

          # LSP
          languages = {
            enableDAP = true;
            enableLSP = true;
            enableFormat = true;
            enableTreesitter = true;
            enableExtraDiagnostics = true;

            bash.enable = true;
            clang.enable = true;
            css.enable = true;
            go.enable = true;
            hcl.enable = true;
            html.enable = true;
            lua.enable = true;
            markdown.enable = true;
            nix.enable = true;
            nu.enable = true;
            php.enable = true;
            python.enable = true;
            sql.enable = true;
            tailwind.enable = true;
            terraform.enable = true;
            ts.enable = true;
            ts.extensions.ts-error-translator.enable = true;
            zig.enable = true;
          };

          lsp = {
            enable = true;
            lightbulb.enable = true;
            lspSignature.enable = true;
            lspkind.enable = true;
            otter-nvim.enable = true;
            trouble.enable = true;

            mappings = {
              goToDeclaration = "<leader>gD";
              goToDefinition = "<leader>gd";
              goToType = "<leader>gt";
              hover = "<leader>h";
              listImplementations = "<leader>gi";
              listReferences = "<leader>gr";
            };
          };

          # UI
          ui = {
            borders.enable = true;
            nvim-ufo.enable = true;
            colorizer.enable = true;
            illuminate.enable = true;
            fastaction.enable = true;
            modes-nvim.enable = true;
            smartcolumn.enable = true;

            breadcrumbs = {
              enable = true;
              navbuddy.enable = true;
            };
          };

          # Themes
          theme = {
            enable = true;
            name = "base16";
            style = "dark";
            transparent = true;
            base16-colors = {
              inherit (config.lib.stylix.colors)
                base00
                base01
                base02
                base03
                base04
                base05
                base06
                base07
                base08
                base09
                base0A
                base0B
                base0C
                base0D
                base0E
                base0F;
            };
          };

          # Plugins
          telescope = {
            enable = true;
            setupOpts.pickers.find_files = {
              hidden = true;
              no_ignore = true;
            };
          };

          autocomplete.nvim-cmp.enable = true;
          autopairs.nvim-autopairs.enable = true;
          dashboard.dashboard-nvim.enable = true;
          notify.nvim-notify.enable = true;
          presence.neocord.enable = true;
          projects.project-nvim.enable = true;
          runner.run-nvim.enable = true;
          statusline.lualine.enable = true;
          utility.motion.precognition.enable  = true;
          utility.outline.aerial-nvim.enable = true;
          utility.preview.markdownPreview.enable = true;
          utility.surround.enable = true;
          utility.vim-wakatime.enable = true;
          visuals.cinnamon-nvim.enable = true;
          visuals.fidget-nvim.enable = true;
          visuals.indent-blankline.enable = true;
          visuals.nvim-scrollbar.enable = true;
          visuals.nvim-web-devicons.enable = true;

          tabline.nvimBufferline = {
            enable = true;
            mappings = {
              closeCurrent = "<leader>x";
              cycleNext = "<Tab>";
              cyclePrevious = "<S-Tab>";
            };
          };

          treesitter = {
            fold = true;
            autotagHtml = true;
            context.enable = true;
            indent.enable = true;
          };

          assistant.copilot = {
            enable = true;
            cmp.enable = true;
            mappings.suggestion.acceptLine = "<M-L>";
          };

          binds = {
            cheatsheet.enable = true;
            whichKey.enable = true;
          };

          comments.comment-nvim = {
            enable = true;
            mappings = {
              toggleCurrentLine = "<C-/>";
              toggleCurrentBlock = "<C-?>";
              toggleOpLeaderLine = "/";
              toggleOpLeaderBlock = "?";
              toggleSelectedLine = "<C-/>";
              toggleSelectedBlock = "<C-?>";
            };
          };

          debugger.nvim-dap = {
            enable = true;
            ui.enable = true;
          };

          filetree.nvimTree = {
            enable = true;
            openOnSetup = false;
            setupOpts.filters = {
              git_ignored = true;
              dotfiles = true;
            };
          };

          git = {
            enable = true;
            vim-fugitive.enable = true;
            gitsigns = {
              enable = true;
              codeActions.enable = true;
            };
          };

          terminal.toggleterm = {
            enable = true;
            lazygit.enable = true;
          };

          extraPlugins = with pkgs.vimPlugins; {
            aerial = {
              package = aerial-nvim;
              setup = "require('aerial').setup {}";
            };

            harpoon = {
              package = harpoon;
              setup = "require('harpoon').setup {}";
              after = ["aerial"];
            };
          };
        };
      };
    };
  };
}
