{inputs, ...}:
with inputs.self.lib;
  {
    defaultSystems = import inputs.systems;
    genSystems = inputs.nixpkgs.lib.genAttrs defaultSystems;

    # Impermanence helpers for home-manager modules
    # These allow other modules to conditionally add persistent dirs/files
    # when the impermanence module is enabled

    # Add directories to persist (general directories)
    mkPersistentDirs = config: dirs: let
      cfg = config.modules.functionality.impermanence;
    in
      inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
        modules.functionality.impermanence.directories = dirs;
      };

    # Add files to persist
    mkPersistentFiles = config: files: let
      cfg = config.modules.functionality.impermanence;
    in
      inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
        modules.functionality.impermanence.files = files;
      };

    # Add .config directories to persist
    mkPersistentConfig = config: dirs: let
      cfg = config.modules.functionality.impermanence;
    in
      inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
        modules.functionality.impermanence.config = dirs;
      };

    # Add .local/share directories to persist
    mkPersistentShare = config: dirs: let
      cfg = config.modules.functionality.impermanence;
    in
      inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
        modules.functionality.impermanence.share = dirs;
      };

    # Add .cache directories to persist
    mkPersistentCache = config: dirs: let
      cfg = config.modules.functionality.impermanence;
    in
      inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
        modules.functionality.impermanence.cache = dirs;
      };

    # Combined helper to add multiple types at once
    mkPersistence = config: {
      directories ? [],
      files ? [],
      config ? [],
      share ? [],
      cache ? [],
    }: let
      cfg = config.modules.functionality.impermanence;
    in
      inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
        modules.functionality.impermanence = {
          directories = directories;
          files = files;
          config = config;
          share = share;
          cache = cache;
        };
      };

    # NixOS-level helper to add persistence through home-manager users
    # Usage: mkNixosPersistence { config, users, persistence }
    # This applies persistence settings to all specified users via home-manager
    mkNixosPersistence = {
      config,
      options,
      users,
      directories ? [],
      files ? [],
      configDirs ? [],
      share ? [],
      cache ? [],
    }: let
      lib = inputs.nixpkgs.lib;
      homeManagerLoaded = builtins.hasAttr "home-manager" options;
      mkUserPersistence = _user: {
        modules.functionality.impermanence = {
          directories = directories;
          files = files;
          config = configDirs;
          share = share;
          cache = cache;
        };
      };
    in
      lib.mkIf homeManagerLoaded {
        home-manager.users = lib.genAttrs users mkUserPersistence;
      };

    # NixOS system-level persistence helper
    # Usage: mkSystemPersistence { config, directories, files }
    # This adds directories/files to the NixOS-level impermanence
    mkSystemPersistence = {
      config,
      directories ? [],
      files ? [],
    }: let
      lib = inputs.nixpkgs.lib;
      cfg = config.modules.functionality.impermanence;
    in
      lib.mkIf cfg.enable {
        modules.functionality.impermanence = {
          inherit directories files;
        };
      };

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
      mkHostConfig = hostName: hostConfig:
        nixpkgs.lib.nixosSystem {
          modules =
            (shared.modules or [])
            ++ [
              hostConfig.path
              {
                nixpkgs.hostPlatform.system = hostConfig.system;
              }
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
