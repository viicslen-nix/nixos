{inputs, ...}: let
  # Import our custom helpers
  moduleHelpers = import ./modules.nix {lib = inputs.nixpkgs.lib;};
  hostsHelpers = import ./hosts.nix {inherit inputs;};
  persistenceHelpers = import ./persistence.nix {inherit inputs;};
  
  defaultSystems = import inputs.systems;
in
  # Merge nixpkgs.lib first, then override with our custom helpers
  inputs.nixpkgs.lib // {
    inherit defaultSystems;
    genSystems = inputs.nixpkgs.lib.genAttrs defaultSystems;

    pkgsFor = system:
      import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    pkgFromSystem = pkg: inputs.nixpkgs.lib.genAttrs defaultSystems (system: ((import inputs.nixpkgs {inherit system; config.allowUnfree = true;}).${pkg}));
    callPackageForSystem = system: path: overrides: let
      pkgs = import inputs.nixpkgs {inherit system; config.allowUnfree = true;};
    in pkgs.callPackage path ({inherit inputs;} // overrides);

    # Custom helpers - these override nixpkgs.lib.{hosts,modules,persistence} if they exist
    hosts = hostsHelpers;
    modules = moduleHelpers;
    persistence = persistenceHelpers;
  }
