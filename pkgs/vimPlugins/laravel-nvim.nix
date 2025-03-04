{pkgs}:
with pkgs;
  vimUtils.buildVimPlugin {
    src = fetchFromGitHub {
      owner = "adalessa";
      repo = "laravel.nvim";
      rev = "v3.2.1";
      sha256 = "sha256-hJmjiBEn48yfULxhgFbiUm455pTxu7D+tN4N2mvyHag=";
    };
    pname = "laravel.nvim";
    version = "3.2.1";
    buildInputs = with vimPlugins; [
      nvim-treesitter-parsers.php
      nvim-treesitter-parsers.json
      promise-async
      nui-nvim
      vim-dotenv
      plenary-nvim
      telescope-nvim
      fzf-lua
      snacks-nvim
    ];
    nvimSkipModule = [
      "laravel.pickers.ui_select.pickers.routes"
    ];
  }
