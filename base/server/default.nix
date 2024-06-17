{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  user,
  ...
}: {
  imports =
    [
      inputs.home-manager.nixosModules.default
      inputs.chaotic.nixosModules.default
      inputs.nur.nixosModules.nur
      ./shell.nix
      ./packages.nix
    ]
    ++ lib.attrsets.mapAttrsToList (name: value: value) outputs.nixosModules;

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

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  environment.etc =
    lib.mapAttrs' (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    })
    config.nix.registry;

  # Linode Specific Configuration
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.usePredictableInterfaceNames = false;

  users.users.neoscode = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCxl3OFptBRpUYBM7lKIAquaQaDSi8XYp4fjXuJUWLeS9iwd7pPoqyWg/AvFTuG5mSX5I91rim4Mp+tSkVRzbxRBcqNHJ9EBBgMi+E3R+Rp7uZFZYQpS7ySdzdfRQtjM4i5ciwjX02RZqIzCcIANB8ttcJKauBHx1/5LVZyqBY517y0MBhdSd3hmcJcFN3T9ppuGYzmnEF8tIXtKmXGMLUYqOSlyhpBDvSthQGKZtAtI7TujGNLWOYedH/f6LkxZTWKMiNlfO3tZoRJcfUqxHzZmvRJYrfh+QrkChAl9S7r3IfVhm1mCngCDsbOqbVDLHNV3IrHdU8xgJUH5t9uQREj5M73k8FTd8pnxV6KmVc1rePiDueDRnvs6L9L0PFyKUPMTC6uZiSkdUH6IM7qLKAcMCmd53TuUVF20RoH4+1hN2LMZLhhhTRu/sOWinz0T4aeDWpKf2JOhoFrx+Hwo6qCFv3mbonVKiEzI1Sd9VHGcrh0pxWdkhOMjd1KU8carvEEu/M/NZTGub0NJhPU7qw9oNJaiQa5xQ4Ka6DTx0DJe4KuIyBs2u1AEc1KrViPD36/1lo/IagYNEN7Sl8ozohEp0J/irmhA4HvMN/kIdUZH3Y1edo2c0EN4BehSnM001Y2rCk8V/DjYkugnCSmdz5xuVAqimebsHadscj/v0jOw== neoscode@laptop" ];
  };

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs;};
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    users.neoscode = import ./home.nix;
  };

  services.openssh.enable = true;

  features.theming.enable = false;
  features.sound.enable = false;

  system.stateVersion = "24.05";
}
