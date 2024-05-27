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
      ./packages.nix
    ]
    ++ lib.attrsets.mapAttrsToList (name: value: value) outputs.nixosModules;

  boot = {
    # Bootloader
    loader.systemd-boot.enable = true;
    loader.systemd-boot.configurationLimit = 10;
    loader.efi.canTouchEfiVariables = false;

    # Enable Plymouth
    plymouth.enable = true;
  };

  services.xserver = {
    # Enable the X11 windowing system.
    enable = true;

    # Configure keymap in X11
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Enable earlyoom to prevent system freezes
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
    extraArgs = let
      catPatterns = patterns: builtins.concatStringsSep "|" patterns;
      preferPatterns = [
        ".firefox-wrappe"
        "ipfs"
        "java"
        ".jupyterhub-wra"
        "Logseq"
      ];
      avoidPatterns = [
        "tlp"
        "bash"
        "mosh-server"
        "sshd"
        "systemd"
        "systemd-logind"
        "systemd-udevd"
        "tmux: client"
        "tmux: server"
      ];
    in [
      "--prefer '^(${catPatterns preferPatterns})$'"
      "--avoid '^(${catPatterns avoidPatterns})$'"
    ];
  };

  # OOM configuration:
  systemd = {
    # Create a separate slice for nix-daemon that is
    # memory-managed by the userspace systemd-oomd killer
    slices."nix-daemon".sliceConfig = {
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "50%";
    };
    services."nix-daemon".serviceConfig.Slice = "nix-daemon.slice";

    # If a kernel-level OOM event does occur anyway,
    # strongly prefer killing nix-daemon child processes
    services."nix-daemon".serviceConfig.OOMScoreAdjust = 1000;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable Flatpaks for some applications missing from Nixpkgs
  services.flatpak.enable = true;

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

  # Define a user account. Don't forget to set a password with ‘passwd’.
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

  # Enable Miscellaneous programs
  programs.nix-ld.enable = true;
  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };

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

  environment.systemPackages = [
    evtest
    libinput
    wl-clipboard
  ];

  # Features
  features = {
    gnome = {
      enable = true;
      enableGdm = true;
      inherit user;
    };

    theming.enable = true;
    appImages.enable = true;
  };

  scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/material-darker.yaml";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
