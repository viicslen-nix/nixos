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
    ../nixos
    ./scripts.nix
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
    libsecret
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
    hyprland = {
      enable = true;
      inherit user;
      palette = config.lib.stylix.colors;
    };

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

    mullvad = {
      enableExludeIPs = true;
      excludedIPs = [
        # Nivoda
        "172.66.43.155"
        "172.66.40.101"
        "104.26.4.176"
        "172.67.68.183"
        "104.26.5.176"
        "108.139.10.82"
        "108.139.10.70"
        "108.139.10.74"
        "108.139.10.67"
      ];
    };
  };
}
