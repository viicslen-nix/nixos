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

    # Generate nixosConfigurations from host definitions
    mkNixosConfigurations = {
      shared ? {},
      hosts ? {},
    }: let
      nixpkgs = inputs.nixpkgs;

      # Build a single nixos configuration
      mkHostConfig = hostName: hostConfig: let
        system = "${hostConfig.system}";
      in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules =
            (shared.modules or [])
            ++ [
              hostConfig.path
            ];
          specialArgs =
            (shared.specialArgs or {})
            // {
              hostName = hostName;
            };
        };

      # Build configurations for all hosts
      configs = nixpkgs.lib.mapAttrs mkHostConfig hosts;
    in
      configs;
  }
  // inputs.nixpkgs.lib
