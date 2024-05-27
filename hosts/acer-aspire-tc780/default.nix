{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  user,
  ...
}: {
  imports = [
    ./hardware.nix
    ../nixos
    ../work
  ];

  home-manager.users.${user} = import ./home.nix;

  environment.systemPackages = with pkgs; [
    neovim
    vimPlugins.nvim-fzf
    delta
    slack
    evtest
    libinput
    wl-clipboard
    libgcc
    gcc13
    insomnia
    nix-alien
    nix-init
    gcc
    zig
    jq
    qemu
    quickemu
    quickgui
    openlens
    mysql80
    skypeforlinux
    bc
    gtop
    libgtop
    gnumake
    cmake
    stable.redisinsight
    kdePackages.kcachegrind
    graphviz
    luakit
    handbrake
    sesh
    clutter
    clutter-gtk

    # Devices
    solaar
    openrgb-with-all-plugins

    # Development
    vscode
    obsidian
    warp-terminal
    jetbrains-toolbox
    jetbrains.phpstorm
    jetbrains.datagrip
    jetbrains.webstorm
    drawio
    mysql-workbench
    siege
    mkcert
    nodejs_20
    corepack_20
  ];

  programs.zsh.shellAliases = {
    dep = "composer exec -- dep";
    takeout = "composer global exec -- takeout";
    nix-dev = "nix develop path:.";
    ds = "dev-shell";
    dsl = "dev-shell laravel";
    dsk = "dev-shell kubernetes";
  };

  features = {
    network.hosts = {
      # Docker
      "kubernetes.docker.internal" = "127.0.0.1";
      "host.docker.internal" = "127.0.0.1";

      # Remote
      "webapps" = "REDACTED";
      "storesites" = "REDACTED";

      # Development
      "home.local" = "127.0.0.1";
      "buggregator.local" = "127.0.0.1";
      "portainer.local" = "127.0.0.1";
      "phpmyadmin.local" = "127.0.0.1";
      "selldiam.test" = "127.0.0.1";
      "mylisterhub.test" = "127.0.0.1";
    };

    docker = {
      enable = true;
      inherit user;
      allowTcpPorts = [
        # Traefik
        80
        443
        8080

        # PHPStorm Xdebug
        9003

        # Portainer
        9443

        # MySQL
        3306

        # Ray
        23517
      ];
    };
  };
}
