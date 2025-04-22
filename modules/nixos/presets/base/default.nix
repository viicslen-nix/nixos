{
  lib,
  pkgs,
  users,
  config,
  inputs,
  outputs,
  ...
}:
with lib; let
  name = "base";
  namespace = "presets";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    defaultShell = mkPackageOption pkgs "zsh" {};

    flakeLocation = mkOption {
      type = types.path;
      default = "/etc/nixos";
      description = ''
        The location of the flake.
      '';
    };

    fonts = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        nerd-fonts.noto
        nerd-fonts.hack
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        nerd-fonts.droid-sans-mono
      ];
      description = ''
        The list of fonts to install.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users =
      lib.attrsets.mapAttrs' (name: value: (nameValuePair name {
        isNormalUser = true;
        description = value.description;
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
        flake = lib.mkDefault cfg.flakeLocation;
      };

      # Enable direnv
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      # Enable Zsh
      zsh.enable = true;
    };

    services = {
      # Enable CUPS to print documents.
      printing.enable = lib.mkDefault true;

      # Enable GVFS for file system access
      gvfs.enable = true;

      # Enable libinput for input devices
      libinput.enable = true;

      # Enable Avahi for network discovery
      avahi.enable = true;

      # Configure keymap in X11
      xserver.xkb = {
        layout = "us";
        variant = "";
      };

      # Enable Smartd for disk monitoring
      smartd = {
        enable = false;
        autodetect = true;
      };
    };

    # Install fonts
    fonts.packages = cfg.fonts;

    # Set default shell
    users.defaultUserShell = pkgs.zsh;

    # Home Manager
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      extraSpecialArgs = {
        inherit inputs outputs;
        stateVersion = config.system.stateVersion;
      };

      users = genAttrs (filter (user: (pathExists ../../../../users/${user})) (attrNames users)) (name: import ../../../../users/${name});
    };

    environment = {
      # Some useful system packages
      systemPackages = with pkgs;
        [
          libsecret
          nil
          nixd
          wget
          curl
          git
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
          htop
          gcc
          glibc
          glib
          just
          gtop
          wmctrl
          lazygit
          busybox
          libinput
          wl-clipboard
          libreoffice
          hunspell
          hunspellDicts.en_US
          bluez
          bluez-tools
        ]
        ++ import ./scripts.nix {
          inherit pkgs;
          flake = cfg.flakeLocation;
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
        FLAKE = lib.mkDefault cfg.flakeLocation;
        NIXOS_OZONE_WL = "1";
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
        inputs.nixpkgs-wayland.overlay
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
        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes";

        # Deduplicate and optimize nix store
        auto-optimise-store = true;

        # Use community binary cache
        substituters = [
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];

        # Limit the number of parallel jobs to avoid OOM
        max-jobs = lib.mkDefault 16;
      };

      # Perform garbage collection weekly to maintain low disk usage
      gc = {
        # automatic = true;
        dates = "weekly";
        options = "--delete-older-than 1w";
      };
    };
  };
}
