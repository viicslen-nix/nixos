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
in {
  imports = [
    inputs.home-manager.nixosModules.default
    inputs.nur.modules.nixos.default
    inputs.agenix.nixosModules.default

    # Universal, always-on modules. `impermanence` is imported for the options
    # the persistence helpers read; it stays disabled unless a host enables it.
    nixosModules.core.localization
    nixosModules.core.network
    nixosModules.core.sound
    nixosModules.services.impermanence
  ];

  # Marker set by the `desktop` preset so other presets (work, personal) can
  # gate GUI-only bits to graphical hosts. Declared here in `base` because it is
  # always imported, so reading it never hits an undeclared option.
  options.modules.presets.desktop.enable =
    mkEnableOption "graphical desktop host (set by the desktop preset)";

  config = {
    system.stateVersion = "26.05";
    systemd.settings.Manager.DefaultTimeoutStopSec = "20s";

    # Every host in this config runs its own firewall management / trusts its
    # LAN, so disable the NixOS firewall globally. Hosts can re-enable if needed.
    networking.firewall.enable = mkForce false;

    users.users =
      lib.attrsets.mapAttrs' (name: value: (nameValuePair name {
        isNormalUser = true;
        inherit (value) description;
        initialPassword = lib.mkIf (value.password == "") name;
        hashedPassword = lib.mkIf (value.password != "") value.password;
        extraGroups = ["networkmanager" "wheel" "adbusers" name];
        shell = pkgs.nushell;
        useDefaultShell = false;
      }))
      users;

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

        # nix-direnv's "direnv: export +AR +AS +..." line is a single ~1.1KB
        # string listing every variable the dev shell touched. On a 100-column
        # terminal it wraps to a dozen rows, and the prompt hook reprints it on
        # every cd, so `clear` leaves the prompt stranded mid-screen. Keep the
        # short status lines that say direnv is doing something; drop the dump.
        # `programs.direnv.silent = true` would suppress all of it instead.
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

    # Set default shell
    users.defaultUserShell = pkgs.zsh;

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
        # Always available: `defaults`/`autostart` declare options other modules
        # read, and `impermanence` supplies the options the persistence helpers
        # consult (it stays disabled unless a host turns it on).
        homeModules.functionality.defaults
        homeModules.functionality.autostart
        homeModules.functionality.impermanence

        ({osConfig, ...}: {
          imports = [
            inputs.agenix.homeManagerModules.default
            inputs.opencode.homeManagerModules.default
            inputs.zed.homeManagerModules.default
          ];

          config = {
            home = {
              # Set state version
              stateVersion = mkDefault osConfig.system.stateVersion;

              # Add local bin to PATH
              sessionPath = ["$HOME/.local/bin"];
            };

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
          pkgs.inputs.packages.scripts.system-update
          pkgs.inputs.packages.scripts.system-upgrade
        ]
        ++ import ./scripts.nix {
          inherit pkgs;
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

    nix = {
      # This will add each flake input as a registry
      # To make nix3 commands consistent with your flake
      registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

      # This will additionally add your inputs to the system's legacy channels
      # Making legacy nix commands consistent as well, awesome!
      nixPath = ["/etc/nix/path"];

      settings = {
        trusted-users = attrNames users;

        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes";

        # Deduplicate and optimize nix store
        auto-optimise-store = true;

        # Use community binary cache
        substituters = [
          "https://nix-community.cachix.org"
          "https://attic.xuyh0120.win/lantian"
          "https://cache.numtide.com"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];

        # Limit the number of parallel jobs to avoid OOM
        # max-jobs = lib.mkDefault 16;
      };

      # Perform garbage collection weekly to maintain low disk usage
      gc = {
        # automatic = true;
        dates = "weekly";
        options = "--delete-older-than 1w";
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
