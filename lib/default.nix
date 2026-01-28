{inputs, ...}:
with inputs.self.lib;
  let
    # Import module helpers
    moduleHelpers = import ./modules.nix { lib = inputs.nixpkgs.lib; };
  in
  {
    defaultSystems = import inputs.systems;
    genSystems = inputs.nixpkgs.lib.genAttrs defaultSystems;

    # Export module helpers
    modules = moduleHelpers;

    # Impermanence helpers for home-manager modules
    # These allow other modules to conditionally add persistent dirs/files
    # when the impermanence module is enabled

    # Add directories to persist (general directories)
    mkPersistentDirs = config: dirs: let
      cfg = config.modules.services.impermanence;
    in
      inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
        modules.services.impermanence.directories = dirs;
      };

    # Add files to persist
    mkPersistentFiles = config: files: let
      cfg = config.modules.services.impermanence;
    in
      inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
        modules.services.impermanence.files = files;
      };

    # Add .config directories to persist
    mkPersistentConfig = config: dirs: let
      cfg = config.modules.services.impermanence;
    in
      inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
        modules.services.impermanence.config = dirs;
      };

    # Add .local/share directories to persist
    mkPersistentShare = config: dirs: let
      cfg = config.modules.services.impermanence;
    in
      inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
        modules.services.impermanence.share = dirs;
      };

    # Add .cache directories to persist
    mkPersistentCache = config: dirs: let
      cfg = config.modules.services.impermanence;
    in
      inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
        modules.services.impermanence.cache = dirs;
      };

    # Combined helper to add multiple types at once
    mkPersistence = config: {
      directories ? [],
      files ? [],
      config ? [],
      share ? [],
      cache ? [],
    }: let
      cfg = config.modules.services.impermanence;
    in
      inputs.nixpkgs.lib.mkIf (cfg.enable && cfg.autoPersistence) {
        modules.services.impermanence = {
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
        modules.services.impermanence = {
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
      cfg = config.modules.services.impermanence;
    in
      lib.mkIf cfg.enable {
        modules.services.impermanence = {
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
      
      # Base path to presets directory
      presetsPath = ../hosts/_shared/presets;
      
      # Base path to hosts directory
      hostsBasePath = ../hosts;

      # Convert preset list to module imports
      # Dynamically resolve preset names to their paths
      presetsToModules = presets:
        if presets == null || presets == []
        then []
        else map (name: import (presetsPath + "/${name}")) presets;

      # Build a single nixos configuration
      mkHostConfig = hostName: hostConfig: let
        # Use provided path or default to hostsBasePath/<hostName>
        hostPath = hostConfig.path or (hostsBasePath + "/${hostName}");
      in
        nixpkgs.lib.nixosSystem {
          modules =
            (shared.modules or [])
            ++ (presetsToModules (hostConfig.presets or []))
            ++ [
              hostPath
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
