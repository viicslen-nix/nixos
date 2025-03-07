{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (builtins) attrNames;
  inherit (lib.options) mkOption;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf mkForce;
  inherit (lib.lists) isList;
  inherit (lib.types) enum either listOf package str;
  inherit (lib.nvim.lua) expToLua;

  cfg = config.vim.languages.php;

  defaultServer = "intelephense";
  servers = {
    phpactor = {
      package = pkgs.phpactor;
      lspConfig = ''
        lspconfig.phpactor.setup{
          capabilities = capabilities,
          on_attach = default_on_attach,
          cmd = ${
          if isList cfg.lsp.package
          then expToLua cfg.lsp.package
          else ''
            {
              "${getExe cfg.lsp.package}",
              "language-server"
            },
          ''
        }
        }
      '';
    };

    phan = {
      package = pkgs.php81Packages.phan;
      lspConfig = ''
        lspconfig.phan.setup{
          capabilities = capabilities,
          on_attach = default_on_attach,
          cmd = ${
          if isList cfg.lsp.package
          then expToLua cfg.lsp.package
          else ''
              {
                "${getExe cfg.lsp.package}",
                "-m",
                "json",
                "--no-color",
                "--no-progress-bar",
                "-x",
                "-u",
                "-S",
                "--language-server-on-stdin",
                "--allow-polyfill-parser"
            },
          ''
        }
        }
      '';
    };


    intelephense = {
      package = pkgs.intelephense;
      lspConfig = ''
        lspconfig.intelephense.setup{
          capabilities = capabilities,
          on_attach = default_on_attach,
          cmd = ${
          if isList cfg.lsp.package
          then expToLua cfg.lsp.package
          else ''
            {
              "${getExe cfg.lsp.package}",
              "--stdio"
            },
          ''
        }
        }
      '';
    };
  };
in {
  options.vim.languages.php = {
    lsp = {
      server = mkForce mkOption {
        description = "PHP LSP server to use";
        type = enum (attrNames servers);
        default = defaultServer;
      };

      package = mkForce mkOption {
        description = "PHP LSP server package, or the command to run as a list of strings";
        example = ''[lib.getExe pkgs.jdt-language-server " - data " " ~/.cache/jdtls/workspace "]'';
        type = either package (listOf str);
        default = servers.${cfg.lsp.server}.package;
      };
    };
  };

  config = mkIf cfg.enable (mkIf cfg.lsp.enable {
    vim.lsp.lspconfig.sources.php-lsp = mkForce servers.${cfg.lsp.server}.lspConfig;
  });
}
