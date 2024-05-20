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
    gcc
    glibc
    glib
    just

    # GUI Apps
    libreoffice-fresh
    tangram
    endeavour
    drawing
    kooha
  ];
}
