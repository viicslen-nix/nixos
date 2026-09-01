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
    inputs.opencode.nixosModules.opencode-web

    # Development tooling
    nixosModules.programs.corepack
    nixosModules.programs.mkcert
    nixosModules.programs.docker

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

    modules = {
      services.opencode-web.enable = true;

      # Shared work servers (identical across every work host).
      core.network.hosts = {
        "webapps" = "50.116.36.170";
        "storesites" = "23.239.17.196";
        "db-prod-master" = "45.33.94.139";
        "db-prod-read" = "45.79.151.62";
      };

      programs = {
        # Docker with the common dev port set. Hosts add hardware-specific bits
        # (nvidiaSupport, storageDriver). WSL force-disables the daemon itself.
        docker = {
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
    };

    programs.zsh.shellAliases = {
      dep = "composer exec -- dep";
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
        jq

        # Build
        libgcc
        gcc13
        gcc
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
        glab
        awscli
        kubectl
        kubernetes-helm
        linode-cli
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
      # GUI apps only on graphical hosts (excluded on WSL/headless)
      ++ lib.optionals config.modules.presets.desktop.enable [
        # Shared GUI dev tools (were duplicated across the work hosts)
        jetbrains-toolbox
        lens
        insomnia
        dbeaver-bin

        luakit
        meld
        github-desktop
        ferdium
        sublime-merge
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
