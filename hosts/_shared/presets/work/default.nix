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
      homeModules.programs.k9s
      homeModules.programs.krr
      ({
        pkgs,
        config,
        ...
      }: let
        # Google's MCP server for databases. Distributed as a prebuilt static Go
        # binary, so it needs no patchelf — it runs on NixOS as-is.
        mcp-toolbox =
          pkgs.runCommand "mcp-toolbox-1.8.0" {
            src = pkgs.fetchurl {
              url = "https://storage.googleapis.com/mcp-toolbox-for-databases/v1.8.0/linux/amd64/toolbox";
              hash = "sha256-jArDuXhdFCStPWZ5nCbF2mldc8dMRSJaMBaJv3051xQ=";
            };
          } ''
            mkdir -p $out/bin
            cp $src $out/bin/toolbox
            chmod +x $out/bin/toolbox
          '';

        # Read-only MCP access to the production MariaDB read replica. Brings the
        # SSH tunnel up (MariaDB binds to the Linode private address only), then
        # serves it over stdio. The password comes from an agenix secret
        # decrypted at activation, so MCP clients can spawn this non-interactively
        # (no 1Password unlock prompt) and it never lands in ~/.claude.json.
        prod-db-mcp = pkgs.writeShellScriptBin "prod-db-mcp" ''
          set -euo pipefail

          PORT="''${MYSQL_PORT:-33061}"

          # ponytail: ControlPersist means only the first call actually dials; the
          # rest reuse the master. `|| true` because ssh exits non-zero when the
          # forward is already bound, which is the success case here.
          ssh -fN db-prod-read-tunnel 2>/dev/null || true

          # Fail once, loudly, instead of letting every query surface as a
          # confusing connection-refused.
          if ! timeout 5 bash -c "</dev/tcp/127.0.0.1/$PORT" 2>/dev/null; then
            echo "prod-db-mcp: tunnel not listening on 127.0.0.1:$PORT" >&2
            exit 1
          fi

          # The mysql prebuilt refuses to start unless all of these are set.
          # Only the password is a secret; the rest just describe the tunnel target.
          export MYSQL_HOST="''${MYSQL_HOST:-127.0.0.1}"
          export MYSQL_PORT="$PORT"
          export MYSQL_USER="''${MYSQL_USER:-mcp_readonly}"
          export MYSQL_DATABASE="''${MYSQL_DATABASE:-mylisterhub_central}"
          export MYSQL_PASSWORD="$(cat ${config.age.secrets.prod-db-mysql-password.path})"
          exec ${mcp-toolbox}/bin/toolbox --prebuilt mysql --stdio
        '';
      in {
        age.secrets.prod-db-mysql-password = {
          file = ../../../../secrets/prod-db/mysql-password.age;
        };

        home.packages = [mcp-toolbox prod-db-mcp];

        programs = {
          ssh.settings = {
            "FmTod" = {
              HostName = "webapps";
              User = "fmtod";
            };

            "SellDiam" = {
              HostName = "webapps";
              User = "inventory";
            };

            "DOS" = {
              HostName = "storesites";
              User = "dostov";
            };

            "BLVD" = {
              HostName = "storesites";
              User = "diamondblvd";
            };

            "EXB" = {
              HostName = "storesites";
              User = "extrabrilliant";
            };

            "DTC" = {
              HostName = "storesites";
              User = "diamondtraces";
            };

            "NFC" = {
              HostName = "storesites";
              User = "naturalfacet";
            };

            "TJD" = {
              HostName = "storesites";
              User = "tiffanyjonesdesigns";
            };

            "47DD" = {
              HostName = "storesites";
              User = "47diamonddistrict";
            };

            "PELA" = {
              HostName = "storesites";
              User = "pelagrino";
            };

            # Tunnel for the read-only MCP database server (see ~/.local/bin/prod-db-mcp).
            # MariaDB binds to the Linode private address only, so 3306 is unreachable
            # from outside the datacenter — the forward target is that private IP.
            "db-prod-read-tunnel" = {
              HostName = "db-prod-read";
              User = "root";
              LocalForward = "33061 192.168.201.159:3306";
              # Fail the ssh call outright if the forward can't bind, instead of
              # succeeding and leaving every query to fail with connection-refused.
              ExitOnForwardFailure = "yes";
              ServerAliveInterval = 30;
              ServerAliveCountMax = 3;
              ControlMaster = "auto";
              ControlPersist = "30m";
            };
          };

          claude-code = let
            claudeCodeRepo = pkgs.fetchFromGitHub {
              owner = "anthropics";
              repo = "claude-code";
              rev = "main";
              sha256 = "sha256-2Kd4oSU3vuDlbo1024hyY0cBA5oeeBPaMWmS3caH6wc=";
            };
          in {
            enable = true;
            package = pkgs.inputs.llm-agents.claude-code;
            plugins.ralph-wiggum = "${claudeCodeRepo}/plugins/ralph-wiggum";
          };
          antigravity-cli = {
            enable = true;
            package = pkgs.inputs.llm-agents.antigravity-cli;
          };
          github-copilot-cli = {
            enable = true;
            package = pkgs.inputs.llm-agents.copilot-cli;
          };
          codex = {
            enable = true;
            package = pkgs.inputs.llm-agents.codex;
          };
        };

        modules.programs = {
          zed.enable = true;
          opencode.enable = true;
          krr = {
            enableK9sIntegration = true;
            package = pkgs.inputs.packages.kubernetes.krr;
          };
          ai = {
            commands.skill-assessment-review = ./ai/skill-assessment-review.md;
            skills.prod-db-operations = ./ai/prod-db-operations.md;
            mcps.prod-db = {
              command = lib.getExe prod-db-mcp;
            };
          };
        };
      })
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
        pkgs.inputs.tuicr.default
        pkgs.inputs.llm-agents.claude-desktop
        pkgs.inputs.llm-agents.antigravity-cli
        pkgs.inputs.packages.php.phpstorm-light
        pkgs.inputs.packages.app-images.responsively
        pkgs.inputs.packages.app-images.t3code
        pkgs.inputs.packages.superset.desktop
        pkgs.inputs.packages.github.copilot-desktop
      ];

    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.1.1w"
      "electron-40.10.5"
      # pulled in via corepack
      "pnpm-9.15.9"
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
