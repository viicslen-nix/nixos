{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; let
  name = "zsh";
  namespace = "features";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    programs = {
      zsh = mkIf cfg.enable {
        enable = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        plugins = [
          {
            name = "powerlevel10k-config";
            src = ./plugins;
            file = "p10k.zsh";
          }
          {
            name = "zsh-powerlevel10k";
            src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/";
            file = "powerlevel10k.zsh-theme";
          }
          {
            name = "fzf-tab";
            src = inputs.fzf-tab;
            file = "fzf-tab.plugin.zsh";
          }
          {
            name = "laravel-sail";
            src = inputs.laravel-sail;
            file = "laravel-sail.plugin.zsh";
          }
        ];

        oh-my-zsh = {
          enable = true;
          plugins = [
            "history"
            "git"
            "gh"
            "npm"
            "node"
            "helm"
            "kubectl"
            "composer"
            "1password"
            "docker"
            "docker-compose"
            "laravel"
            "zoxide"
            "zsh-interactive-cd"
          ];
        };

        shellAliases = {
          ls = "lsd";
          l = "ls -l";
          la = "ls -a";
          lla = "ls -la";
          lt = "ls --tree";
          pn = "pnpm";
          cat = "bat";
          vim = "nvim";
          ts = "tmux-session";
          ds = "dev-shell";
          dsl = "dev-shell laravel";
          dsk = "dev-shell kubernetes";
          o = "xdg-open";
          spf = "search-package-files";
        };
      };

      atuin.enableZshIntegration = true;
      keychain.enableZshIntegration = true;
      direnv.enableZshIntegration = true;
      carapace.enableZshIntegration = true;
      thefuck.enableZshIntegration = true;
      zoxide.enableZshIntegration = true;
      yazi.enableZshIntegration = true;
    };
  };
}
