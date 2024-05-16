{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  user,
  ...
}: {
  home.packages = with pkgs; [
    vivaldi-wayland
    microsoft-edge-wayland
  ];

  features.lan-mouse.enable = true;

  programs.ray.enable = true;
  programs.tinkerwell.enable = true;

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
