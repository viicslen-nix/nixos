{inputs, ...}:
with inputs.self.lib;
  {
    defaultSystems = import inputs.systems;
    genSystems = inputs.nixpkgs.lib.genAttrs defaultSystems;

    pkgsFor = system:
      import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    pkgFromSystem = pkg: genSystems (system: (pkgsFor system).${pkg});
    callPackageForSystem = system: path: overrides: ((pkgsFor system).callPackage path ({inherit inputs;} // overrides));

    hosts = import ./hosts.nix {inherit inputs;};
    modules = import ./modules.nix {lib = inputs.nixpkgs.lib;};
    persistence = import ./persistence.nix {inherit inputs;};
  }
  // inputs.nixpkgs.lib
