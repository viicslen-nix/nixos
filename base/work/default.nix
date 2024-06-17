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
    ./scripts.nix
  ];

  home-manager.users.${user} = import ./home.nix;

  # Lan Mouse
  networking.firewall.allowedTCPPorts = [4242];

  environment.systemPackages = with pkgs; [
    # Communication
    slack

    # Formatters
    delta
    jq

    # Editors
    vimPlugins.nvim-fzf
    vscode

    # Build
    libgcc
    gcc13
    gcc
    zig
    bc
    gnumake
    cmake
    luakit

    # Tools
    nodejs_20
    corepack_20
    mysql80
    mkcert
    awscli
    meld
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
