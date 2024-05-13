{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  user,
  ...
}: {
  home.sessionPath = [
    "~/.local/share/JetBrains/Toolbox/scripts"
  ];

  home.file.".config/autostart/jetbrains-toolbox.desktop".text = ''
    [Desktop Entry]
    Name=Jetbrains Toolbox
    Exec=${pkgs.jetbrains-toolbox}/bin/jetbrains-toolbox --minimize %U
    Terminal=false
    Type=Application
    Icon=~/.local/share/JetBrains/Toolbox/toolbox.svg
    StartupWMClass=Jetbrains Toolbox
    Comment=Manage all your developer tools in one app
    Categories=Development;
    MimeType=x-scheme-handler/jetbrains;
    X-GNOME-Autostart-enabled=true
    StartupNotify=false
    X-GNOME-Autostart-Delay=10
    X-MATE-Autostart-Delay=10
    X-KDE-autostart-after=panel
  '';

  home.packages = with pkgs; [
    brave
    vivaldi
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
    shortcut = " ";
    mouse = true;
    baseIndex = 1;
    keyMode = "vi";
    newSession = true;
    historyLimit = 10000;
    shell = "${pkgs.zsh}/bin/zsh";
    tmuxinator.enable = true;
  };
}
