{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  user,
  ...
}: {
  imports =
    [
      inputs.nvchad.homeManagerModule
    ]
    ++ lib.attrsets.mapAttrsToList (name: value: value) outputs.homeManagerModules;

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

  features.zsh.enable = true;
  features.tmux.enable = true;

  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      delta.enable = true;
      aliases = {
        # nah = "!f(){ git reset --hard; git clean -df; if [ -d ".git/rebase-apply" ] || [ -d ".git/rebase-merge" ]; then git rebase --abort; fi; }; f";
        forget = "!git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -D";
        forgetlist = "!git fetch -p && git branch -vv | awk '/: gone]/{print $1}'";
        uncommit = "reset --soft HEAD~0";
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
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
