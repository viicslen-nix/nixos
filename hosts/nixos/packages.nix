{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # CLI Tools
    wget
    curl
    git
    fzf
    lshw
    chezmoi
    lsd
    bat
    ripgrep
    gh
    unzip
    jq
    tmux
    zoxide
    htop
    xeyes
  
    # GUI Apps
    libreoffice-fresh
    tangram
    endeavour
    handbrake
    mailspring
    solaar
    microsoft-edge
    drawing
    kooha
    openrgb-with-all-plugins
  ];

  programs = {
    firefox.enable = true;
  };
}
