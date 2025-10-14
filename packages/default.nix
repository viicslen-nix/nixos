{inputs, ...}: {
  imports = [
    inputs.pkgs-by-name.flakeModule
  ];
  perSystem = {
    system,
    config,
    pkgs,
    lib,
    ...
  }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          local = config.packages;
        })
      ];
    };

    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    # legacyPackages = lib.packagesFromDirectoryRecursive {
    #   inherit (pkgs) callPackage;
    #   directory = ./by-name;
    # };

    # pkgsDirectory = ./by-name;
    # pkgsNameSeparator = ".";
  };
}
