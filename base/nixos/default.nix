# Edit this configuration file to define what should be installed on
# your base system system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  user,
  name,
  ...
}: {
  # Modules
  imports =
    [
      inputs.home-manager.nixosModules.default
      inputs.chaotic.nixosModules.default
      inputs.nur.nixosModules.nur
      ./packages.nix
      ./scripts.nix
    ]
    ++ lib.attrsets.mapAttrsToList (name: value: value) outputs.nixosModules;

  system.stateVersion = "24.05";

  # Enable Plymouth
  boot.plymouth.enable = true;

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
      inputs.nvchad.overlays.default
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

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  environment.etc =
    lib.mapAttrs' (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    })
    config.nix.registry;

  # Install fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    (nerdfonts.override {
      fonts = [
        "FiraCode"
        "JetBrainsMono"
        "DroidSansMono"
      ];
    })
  ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = lib.mkDefault true;

  # Set user name and groups
  users.users.${user} = {
    isNormalUser = true;
    description = name;
    extraGroups = ["networkmanager" "wheel" user];
  };

  # Set default shell
  users.defaultUserShell = pkgs.zsh;

  # Home Manager
  home-manager = {
    extraSpecialArgs = {inherit inputs outputs user;};
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    users.${user} = import ./home.nix;
  };

  # Enable NH for easier system rebuilds
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/${user}/.nix/";
  };

  # Enable direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Enable Zsh
  programs.zsh.enable = true;

  # Set flake path in environment
  environment.sessionVariables = {
    FLAKE = "/home/${user}/.nix/";
  };
}
