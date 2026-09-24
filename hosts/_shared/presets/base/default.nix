{
  lib,
  pkgs,
  users,
  config,
  inputs,
  outputs,
  nixosModules,
  homeModules,
  ...
}:
with lib; let
  flakeLocation = "/etc/nixos";

  caches = import ../../../../caches.nix {inherit lib;};

  # Shaped from the agenix secret at activation; tmpfs, so neither persists.
  nixAccessTokens = "/run/nix-access-tokens";
  nixDaemonEnv = "/run/nix-daemon-env";
in {
  imports = [
    inputs.home-manager.nixosModules.default
    inputs.nur.modules.nixos.default
    inputs.agenix.nixosModules.default

    # Keep `impermanence`: it declares the options the persistence helpers read.
    nixosModules.core.localization
    nixosModules.core.network
    nixosModules.services.impermanence
  ];

  # Declare it here, not in `desktop`: only `base` is always imported.
  options.modules.presets.desktop.enable =
    mkEnableOption "graphical desktop host (set by the desktop preset)";

  config = {
    system.stateVersion = "26.05";
    systemd.settings.Manager.DefaultTimeoutStopSec = mkDefault "20s";

    # Every host trusts its LAN; `mkForce` means a host cannot re-enable this.
    networking.firewall.enable = mkForce false;

    users = {
      mutableUsers = mkDefault false;
      extraUsers.root.hashedPassword = mkDefault "$6$hl2eKy3qKB3A7hd8$8QMfyUJst4sRAM9e9R4XZ/IrQ8qyza9NDgxRbo0VAUpAD.hlwi0sOJD73/N15akN9YeB41MJYoAE9O53Kqmzx/";

      users =
        lib.attrsets.mapAttrs' (name: value: (nameValuePair name {
          isNormalUser = true;
          inherit (value) description;
          initialPassword = lib.mkIf (value.password == "") name;
          hashedPassword = lib.mkIf (value.password != "") value.password;
          extraGroups = ["networkmanager" "wheel" name];
          shell = pkgs.zsh;
          useDefaultShell = false;
        }))
        users;
    };

    programs = {
      # Enable NH for easier system rebuilds
      nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
        flake = lib.mkDefault flakeLocation;
      };

      # Enable direnv
      direnv = {
        enable = true;
        nix-direnv.enable = true;

        # Not `silent = true` — that would drop the useful status lines too.
        settings.global.log_filter = "^(loading|using|nix-direnv)";
      };

      # Enable Zsh
      zsh.enable = true;
    };

    services = {
      # Enable fuse filesystem to provide common FHS-style paths like /bin/bash,
      # so scripts with #!/bin/bash work unchanged.
      envfs.enable = true;
    };

    # Home Manager
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      extraSpecialArgs = {
        inherit inputs outputs homeModules;
        stateVersion = config.system.stateVersion;
      };

      # Universal home-manager config, applied to every user on every host.
      sharedModules = [
        # Keep all three: they declare options other modules read, even disabled.
        homeModules.functionality.defaults
        homeModules.functionality.autostart
        homeModules.functionality.impermanence

        ({
          config,
          osConfig,
          ...
        }: {
          imports = [
            inputs.agenix.homeManagerModules.default
            inputs.opencode.homeManagerModules.default
            inputs.opencode.homeManagerModules.opencode2
            inputs.zed.homeManagerModules.default
          ];

          config = {
            home = {
              # Set state version
              stateVersion = mkDefault osConfig.system.stateVersion;

              # Add local bin to PATH
              sessionPath = ["$HOME/.local/bin"];

              # Every home-manager module that honours this drops its $HOME
              # dotfile for the XDG dir — and exports the tool's env var with it
              # (GTK2_RC_FILES, CODEX_HOME, COPILOT_HOME). Flipping it back
              # strands whatever state already moved.
              preferXdgDirectories = true;
            };

            # xresources predates preferXdgDirectories and needs saying twice.
            xresources.path = "${config.xdg.configHome}/xresources";

            # Allow home-manager to manage itself
            programs.home-manager.enable = mkDefault true;

            # Use sd-switch to manage systemd services
            systemd.user.startServices = mkDefault "sd-switch";

            # Configure the package manager
            xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs.nix;

            # Disable manual
            manual.manpages.enable = mkDefault false;
            programs.man.enable = mkDefault false;
          };
        })
      ];

      users = genAttrs (filter (user: (pathExists ../../../../users/${user})) (attrNames users)) (name: import ../../../../users/${name});
    };

    environment = {
      # Some useful system packages (universal CLI tooling)
      systemPackages = with pkgs;
        [
          libsecret
          nil
          nixd
          wget
          curl
          git
          jujutsu
          fzf
          lshw
          lsd
          bat
          ripgrep
          unzip
          pigz
          jq
          jc
          pv
          tmux
          zoxide
          btop
          gcc
          glibc
          glib
          just
          lazygit
          busybox

          # Keep explicit: environment.shells advertises nu, but the shell is zsh.
          nushell

          pkgs.inputs.packages.scripts.system-update
          pkgs.inputs.packages.scripts.system-upgrade
        ]
        ++ import ./scripts.nix {
          inherit lib pkgs;
          flake = flakeLocation;
        };

      # This will additionally add your inputs to the system's legacy channels
      # Making legacy nix commands consistent as well, awesome!
      etc =
        lib.mapAttrs' (name: value: {
          name = "nix/path/${name}";
          value.source = value.flake;
        })
        config.nix.registry;

      # Set flake path in environment
      sessionVariables = {
        NH_FLAKE = lib.mkDefault flakeLocation;
      };

      # Install available shells
      shells = with pkgs; [
        zsh
        bashInteractive
        fish
        nushell
      ];
    };

    nixpkgs = {
      # You can add overlays here
      overlays = [
        # Add overlays your own flake exports (from overlays and pkgs dir):
        outputs.overlays.additions
        outputs.overlays.modifications
        outputs.overlays.stable-packages
        outputs.overlays.unstable-packages
        outputs.overlays.flake-inputs

        # After flake-inputs: it patches an attr that overlay creates.
        outputs.overlays.superset-fork

        inputs.nix-alien.overlays.default
        inputs.nix-cachyos-kernel.overlays.pinned
        inputs.llm-agents.overlays.shared-nixpkgs
      ];
      # Configure your nixpkgs instance
      config = {
        # Disable if you don't want unfree packages
        allowUnfree = true;
      };
    };

    # Encrypt every secret to the portable ~/.ssh/agenix key, never to host keys.
    age = {
      identityPaths =
        map (name: "/home/${name}/.ssh/agenix") (attrNames users)
        ++ ["/etc/ssh/ssh_host_ed25519_key"];

      # Bare PAT only — no trailing newline, no surrounding syntax.
      secrets.nix-token.file = ../../../../secrets/github/nix-token.age;
    };

    # Never `writeText` the token; keep `deps`/`if` — an `exit` skips later snippets.
    system.activationScripts.nixTokenFiles = {
      deps = ["agenix"];
      text = ''
        # mode, group, destination; content on stdin. Created 0400 and only then
        # relaxed, and renamed into place, so no reader ever sees a partial or
        # briefly over-permissive token.
        shapeToken() {
          ( umask 0277
            ${pkgs.coreutils}/bin/cat > "$3.tmp" )
          ${pkgs.coreutils}/bin/chgrp "$2" "$3.tmp"
          ${pkgs.coreutils}/bin/chmod "$1" "$3.tmp"
          ${pkgs.coreutils}/bin/mv -f "$3.tmp" "$3"
        }

        if [ -r ${config.age.secrets.nix-token.path} ]; then
          token=$(${pkgs.coreutils}/bin/cat ${config.age.secrets.nix-token.path})

          # `pkgs.fetchurl` reads its `impureEnvVars` from the nix-daemon's
          # environment, not your shell's — this is the only way a fixed-output
          # derivation can authenticate to a private GitHub release asset.
          printf 'GITHUB_TOKEN=%s\n' "$token" \
            | shapeToken 0400 root ${nixDaemonEnv}

          # Flake *inputs* are the mirror image: fetched by the client process,
          # which never sees the daemon's environment. Group-readable, because a
          # root-only file would break `nix run` for the user who needs it.
          printf 'access-tokens = github.com=%s\n' "$token" \
            | shapeToken 0440 users ${nixAccessTokens}

          unset token
        fi
      '';
    };

    systemd.services.nix-daemon.serviceConfig.EnvironmentFile = "-${nixDaemonEnv}";

    # crates.io 403s nix's own User-Agent from this host; no spaces, $NIX_CURL_FLAGS is word-split.
    systemd.services.nix-daemon.environment.NIX_CURL_FLAGS = "-A Mozilla/5.0";

    nix = {
      # This will add each flake input as a registry
      # To make nix3 commands consistent with your flake
      registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

      # This will additionally add your inputs to the system's legacy channels
      # Making legacy nix commands consistent as well, awesome!
      nixPath = ["/etc/nix/path"];

      # Keep `!include`, not `include` — the file is absent until agenix runs.
      extraOptions = ''
        !include ${nixAccessTokens}
      '';

      settings = {
        trusted-users = attrNames users;

        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes";

        # Deduplicate and optimize nix store
        auto-optimise-store = true;

        # Add a cache in caches.nix at the repo root, never here.
        substituters = caches.substituters "base";
        trusted-public-keys = caches.trustedKeys "base";

        # Limit the number of parallel jobs to avoid OOM
        # max-jobs = lib.mkDefault 16;
      };
    };

    # Skip building the HTML NixOS/package/info docs on every rebuild (eval +
    # closure cost across the preset stack). Keep man pages.
    documentation = {
      nixos.enable = false;
      doc.enable = false;
      info.enable = false;
    };
  };
}
