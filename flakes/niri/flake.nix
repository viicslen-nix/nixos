{
  description = "Niri desktop environment configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-cli = {
      url = "github:AvengeMedia/danklinux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    niri-flake,
    dankMaterialShell,
    dgop,
    dms-cli,
    ...
  }: {
    # Main NixOS module output - exposes the niri desktop environment configuration
    nixosModules.default = {config, lib, pkgs, options, ...}:
      import ./default.nix {
        inherit config lib pkgs options inputs;
      };

    # Alias for clarity
    nixosModules.niri = self.nixosModules.default;
  };
}
