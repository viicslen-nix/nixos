{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; {
  imports = [inputs.opencode.nixosModules.opencode-web];
  config = {
    home-manager.sharedModules = [./home.nix];

    modules = {
      services.opencode-web.enable = true;

      # Shared work servers (identical across every work host).
      core.network.hosts = {
        "webapps" = "50.116.36.170";
        "storesites" = "23.239.17.196";
        "db-prod-master" = "50.116.56.10";
        "db-prod-read" = "50.116.56.249";
        "db-staging-master" = "45.79.180.78";
        "db-staging-read" = "45.79.180.88";
      };

      programs = {
        corepack.enable = true;
        mkcert.enable = true;

        # Docker with the common dev port set. Hosts add hardware-specific bits
        # (nvidiaSupport, storageDriver). WSL force-disables the daemon itself.
        docker = {
          enable = true;
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

      containers = {
        traefik.enable = true;
        mysql.enable = true;
        redis.enable = true;
        soketi.enable = true;
        qdrant.enable = true;
        centrifugo.enable = true;
        meilisearch.enable = true;
        buggregator.enable = true;
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
        go
        gosec
        pkg-config
        opus-tools
        opusfile
        opustags

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
        sublime4
        sublime-merge
        pkgs.inputs.packages.app-images.responsively
        pkgs.inputs.packages.app-images.t3code
        pkgs.inputs.packages.superset.desktop
        pkgs.inputs.packages.github.copilot-desktop
        pkgs.inputs.llm-agents.claude-desktop
      ];

    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.1.1w"
      "electron-40.10.5"
    ];

    # sublimetext4 is marked broken (its plug-in host needs the insecure OpenSSL
    # we already permit above) and flagged for the Python 3.3 removal. We keep
    # using it deliberately, so silence both problem warnings.
    nixpkgs.config.problems.handlers.sublimetext4 = {
      broken = "ignore";
      removal = "ignore";
    };
  };
}
