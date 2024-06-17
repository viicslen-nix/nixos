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

  home.stateVersion = "24.05";
  home.username = user;
  home.homeDirectory = "/home/${user}";

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.sessionVariables = {
    EDITOR = "nvim";
    NIXOS_OZONE_WL = "1";
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    tmux.enableShellIntegration = true;
  };

  programs.tmux = {
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
}
