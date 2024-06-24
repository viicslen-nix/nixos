# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  user,
  ...
}: {
  # Modules
  imports =
    [
      inputs.home-manager.nixosModules.default
      inputs.chaotic.nixosModules.default
      inputs.nur.nixosModules.nur
      ./shell.nix
      ./scripts.nix
      ./packages.nix
    ]
    ++ lib.attrsets.mapAttrsToList (name: value: value) outputs.nixosModules;

  system.stateVersion = "24.05";

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
  
  users.users.${user} = {
    isNormalUser = true;
    description = "Victor R";
    extraGroups = ["networkmanager" "wheel" user];
  };

  # Home Manager
  home-manager = {
    extraSpecialArgs = {inherit inputs outputs user;};
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    users.${user} = import ./home.nix;
  };

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

  # Enable NH for easier system rebuilds
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/${user}/.nix/";
  };

  environment.sessionVariables = {
    FLAKE = "/home/${user}/.nix/";
  };

  environment.systemPackages = with pkgs; [
    evtest
    libinput
    wl-clipboard
  ];
}
