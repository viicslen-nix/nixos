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
  }
  // inputs.nixpkgs.lib
