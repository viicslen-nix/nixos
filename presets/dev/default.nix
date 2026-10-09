{nixosModules, ...}: {
  imports = [
    nixosModules.programs.corepack
    nixosModules.programs.mkcert
    nixosModules.programs.docker
    nixosModules.programs.podman

    # Container stack. The `containers` base module declares the shared
    # settings each container module reads, and the containers consult mkcert.
    nixosModules.containers.base
    nixosModules.containers.traefik
    nixosModules.containers.mysql
    nixosModules.containers.redis
    nixosModules.containers.soketi
    nixosModules.containers.qdrant
    nixosModules.containers.centrifugo
    nixosModules.containers.meilisearch
    nixosModules.containers.buggregator
  ];

  config = {
    home-manager.sharedModules = [./home.nix];

    modules = {
      core.network.hosts = {
        # Docker
        "kubernetes.docker.internal" = "127.0.0.1";
        "host.docker.internal" = "127.0.0.1";

        # Local services
        "ai.local" = "127.0.0.1";
        "home.local" = "127.0.0.1";
        "buggregator.local" = "127.0.0.1";
        "soketi.local" = "127.0.0.1";
        "npm.local" = "127.0.0.1";
        "portainer.local" = "127.0.0.1";
        "phpmyadmin.local" = "127.0.0.1";
      };

      # Both engines are imported; each enables itself from `backend` and reads
      # these shared knobs. Hosts add the hardware-specific bits (nvidiaSupport,
      # storageDriver). WSL force-disables the daemon itself.
      containers.settings.allowTcpPorts = [
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

    programs.zsh.shellAliases = {
      takeout = "composer global exec -- takeout";
      nix-dev = "nix develop path:.";
    };

    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.1.1w"
      "electron-40.10.5"
      # pulled in via corepack
      "pnpm-9.15.9"
    ];
  };
}
