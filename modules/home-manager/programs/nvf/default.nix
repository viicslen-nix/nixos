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
    ./keybinds.nix
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

          theme = {
            enable = mkForce false;
          };

          startPlugins = ["onedark" "base16"];
          luaConfigRC.theme = inputs.nvf.lib.nvim.dag.entryBefore ["pluginConfigs" "lazyConfigs"] ''
            require('onedark').setup {
              transparent = true,
              style = "darker"
            }
            require('onedark').load()
          '';

          # LSP
          languages = {
            enableDAP = true;
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
            python.enable = true;
            sql.enable = true;
            tailwind.enable = true;
            terraform.enable = true;
            zig.enable = true;
            php = {
              enable = true;
              lsp.server = "intelephense";
            };

            ts = {
              enable = true;
              extensions.ts-error-translator.enable = true;
            };
          };

          lsp = {
            enable = true;
            lightbulb.enable = true;
            lspSignature.enable = true;
            lspkind.enable = true;
            otter-nvim.enable = true;
            trouble.enable = true;
          };

          # UI
          ui = {
            borders.enable = true;
            nvim-ufo.enable = true;
            colorizer.enable = true;
            illuminate.enable = true;
            fastaction.enable = true;
            modes-nvim.enable = true; # Look
            smartcolumn.enable = true;

            breadcrumbs = {
              enable = true;
              navbuddy.enable = true;
            };
          };

          # Plugins
          telescope = {
            enable = true;
            setupOpts.pickers.find_files = {
              find_command = [
                (lib.getExe pkgs.fd)
                "--type=file"
                "--unrestricted"
              ];
              hidden = true;
              no_ignore = true;
            };
          };

          treesitter = {
            fold = true;
            autotagHtml = true;
            context.enable = true;
            indent.enable = true;
          };

          autocomplete.nvim-cmp.enable = true;
          autopairs.nvim-autopairs.enable = true;
          dashboard.dashboard-nvim.enable = true;
          presence.neocord.enable = true;
          projects.project-nvim.enable = true;
          runner.run-nvim.enable = true;
          statusline.lualine.enable = true;
          tabline.nvimBufferline.enable = true;
          comments.comment-nvim.enable = true;

          notify.nvim-notify = {
            enable = true;
            setupOpts = {
              background_colour = "#000000";
            };
          };

          utility = {
            outline.aerial-nvim.enable = true;
            preview.markdownPreview.enable = true;
            surround.enable = true;
            vim-wakatime.enable = true;
          };

          visuals = {
            cinnamon-nvim.enable = true;
            indent-blankline.enable = true;
            nvim-scrollbar.enable = true;
            nvim-web-devicons.enable = true;

            fidget-nvim.enable = false;
          };

          assistant.copilot = {
            enable = true;
            cmp.enable = true;
          };

          binds = {
            cheatsheet.enable = true;
            whichKey.enable = true;
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

          lazy.plugins = with pkgs.vimPlugins; {
            "harpoon" = {
              package = harpoon;
              setupModule = "harpoon";
              setupOpts = {};
              lazy = true;
            };

            "neotest" = {
              package = neotest;
              setupModule = "neotest";
              setupOpts = {};
              lazy = true;
            };

            "neotest-pest" = {
              package = pkgs.myVimPlugins.neotest-pest;
              setupModule = "neotest-pest";
              setupOpts = {};
              lazy = true;
            };

            "laravel.nvim" = {
              package = pkgs.myVimPlugins.laravel-nvim;
              setupModule = "laravel";
              cmd = ["Laravel"];
              lazy = true;
            };
          };
        };
      };
    };
  };
}
