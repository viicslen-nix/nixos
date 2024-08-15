{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  user,
  ...
}: {
  imports = [
    inputs.nvchad.homeManagerModule
  ] ++ lib.attrsets.mapAttrsToList (name: value: value) outputs.homeManagerModules;

  systemd.user.startServices = "sd-switch";

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "24.05";

    sessionVariables = {
      EDITOR = "nvim";
      NIXOS_OZONE_WL = "1";
    };
  };

  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      delta.enable = true;
      aliases = {
        # nah = "!f(){ git reset --hard; git clean -df; if [ -d ".git/rebase-apply" ] || [ -d ".git/rebase-merge" ]; then git rebase --abort; fi; }; f";
	      forget="!git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -D";
        forgetlist="!git fetch -p && git branch -vv | awk '/: gone]/{print $1}'";
	      uncommit = "reset --soft HEAD~0";
      };
    };

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      plugins = [
        {
          name = "powerlevel10k-config";
          src = ./shell;
          file = "p10k.zsh";
        }
        {
          name = "zsh-powerlevel10k";
          src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/";
          file = "powerlevel10k.zsh-theme";
        }
      ];

      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "npm"
          "history"
          "node"
          "rust"
          "deno"
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
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
    };

    tmux = {
      enable = true;
      shortcut = "Space";
      mouse = true;
      baseIndex = 1;
      keyMode = "vi";
      historyLimit = 10000;
      tmuxinator.enable = true;
      shell = "${pkgs.zsh}/bin/zsh";
      extraConfig = "source-file ~/.tmux.conf";
    };

    hstr = {
      enable = true;
      enableZshIntegration = true;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    nvchad = {
      enable = true;
      backup = false;
      extraConfig = inputs.nvchad-config;
      extraPackages = with pkgs; [
        nixd
        python3
        php83
        php83Packages.composer
        docker-compose-language-service
        dockerfile-language-server-nodejs
        nodePackages.bash-language-server
        stable.nodePackages.volar
      ];
    };
  };
}
