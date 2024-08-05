{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  user,
  ...
}: {
  imports = [] ++ lib.attrsets.mapAttrsToList (name: value: value) outputs.homeManagerModules;

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
  };
}
