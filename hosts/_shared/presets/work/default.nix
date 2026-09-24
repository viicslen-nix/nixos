{
  lib,
  pkgs,
  config,
  inputs,
  nixosModules,
  homeModules,
  ...
}:
with lib; {
  imports = [
    inputs.ai.nixosModules.opencode-web

    # Development tooling
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
    home-manager.sharedModules = [
      ./home.nix
      homeModules.programs.k9s
      homeModules.programs.krr
    ];

    # Cert is public and feeds the build-time bundle; only the key is a secret.
    age.secrets.mkcert-rootCA-key.file = ../../../../secrets/mkcert/rootCA-key.age;

    modules = {
      programs.mkcert.rootCA = {
        enable = true;
        certPath = ../../../../secrets/mkcert/rootCA.pem;
        keyPath = config.age.secrets.mkcert-rootCA-key.path;
      };

      core.network.hosts = {
        # Shared work servers
        "webapps" = "50.116.36.170";
        "storesites" = "23.239.17.196";
        "db-prod-master" = "45.33.94.139";
        "db-prod-read" = "45.79.151.62";

        # Docker
        "kubernetes.docker.internal" = "127.0.0.1";
        "host.docker.internal" = "127.0.0.1";

        # Local dev
        "ai.local" = "127.0.0.1";
        "home.local" = "127.0.0.1";
        "buggregator.local" = "127.0.0.1";
        "soketi.local" = "127.0.0.1";
        "npm.local" = "127.0.0.1";
        "portainer.local" = "127.0.0.1";
        "phpmyadmin.local" = "127.0.0.1";
        "erpnext.test" = "127.0.0.1";
        "selldiam.test" = "127.0.0.1";
        "mylisterhub.test" = "127.0.0.1";
        "vite.mylisterhub.test" = "127.0.0.1";
        "app.mylisterhub.test" = "127.0.0.1";
        "admin.mylisterhub.test" = "127.0.0.1";
        "*.mylisterhub.test" = "127.0.0.1";
        "time-tracker.test" = "127.0.0.1";
        "labreu.test" = "127.0.0.1";
        "store.labreu.test" = "127.0.0.1";
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

    environment.systemPackages = with pkgs; let
      phpWithExtensions = php.buildEnv {
        extensions = {
          enabled,
          all,
        }:
          enabled
          ++ (with all; [
            xdebug
            imagick
            redis
          ]);
        extraConfig = ''
          memory_limit=-1
          max_execution_time=0
        '';
      };
    in
      [
        # Formatters
        delta

        # Build
        libgcc
        gcc13
        zig
        bc
        gnumake
        cmake
        phpWithExtensions
        phpWithExtensions.packages.composer
        nodejs_22
        bun
        # vite+ ("The Unified Toolchain for the Web"); binary is `vp`.
        # Not in nixpkgs — reached through omniflake's index.
        pkgs.inputs.nix-vite-plus.default
        go
        gosec
        pkg-config
        opus-tools
        opusfile
        opustags
        node-gyp

        # Tools (CLI/TUI)
        gh
        uv
        glab
        awscli
        kubectl
        linode-cli
        wrangler
        cloudflared
        kubernetes-helm
        atlas
        devbox
        act
        gh-dash
        percona-toolkit
        pkgs.inputs.hunk.hunk
        # pkgs.inputs.gitura.default
        pkgs.inputs.ghost-backup.default

        # AI (CLI)
        pkgs.inputs.packages.coderabbit
        pkgs.inputs.packages.superset.cli
      ]
      ++ import ./scripts.nix {inherit pkgs;}
      # GUI apps only on graphical hosts (excluded on WSL/headless)
      ++ lib.optionals config.modules.presets.desktop.enable [
        vscode-fhs
        jetbrains-toolbox
        lens
        insomnia
        dbeaver-bin
        pkgs.inputs.tuicr.default
        pkgs.inputs.llm-agents.claude-desktop
        pkgs.inputs.llm-agents.antigravity-cli
        pkgs.inputs.packages.app-images.responsively
        pkgs.inputs.packages.superset.desktop
        pkgs.inputs.packages.github.copilot-desktop
      ];

    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.1.1w"
      "electron-40.10.5"
      # pulled in via corepack
      "pnpm-9.15.9"
    ];
  };
}
