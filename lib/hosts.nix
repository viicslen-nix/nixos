{...}: {
  # Generate nixosConfigurations from host definitions
  mkNixosConfigurations = hostsPath: specialArgs: let
    nixpkgs = inputs.nixpkgs;
    lib = nixpkgs.lib;

    # Import hosts configuration (shared and hosts definitions)
    hostsConfig = import hostsPath {};
    shared = hostsConfig.shared or {};
    hosts = hostsConfig.hosts or {};

    # Derive presets path from hosts path
    presetsPath = hostsPath + "/_shared/presets";

    # Convert preset list to module imports
    # Dynamically resolve preset names to their paths
    presetsToModules = presets:
      if presets == null || presets == []
      then []
      else map (name: import (presetsPath + "/${name}")) presets;

    # Collect all NixOS modules from exports
    # Auto-discovered exports can be either:
    # - A set of modules (e.g., core = { network = ...; sound = ...; })
    # - A single module (e.g., containers = <module function>)
    allNixosModules = let
      # Get all exported module names except special ones
      moduleNames =
        builtins.filter
        (name: name != "all" && name != "default")
        (builtins.attrNames outputs.nixosModules);

      # For each export, check if it's a set (category) or a function (single module)
      collectModules = name: let
        export = outputs.nixosModules.${name};
        exportType = builtins.typeOf export;
      in
        if exportType == "set"
        then lib.attrsets.mapAttrsToList (_: value: value) export # It's a category
        else [export]; # It's a single module
    in
      builtins.concatLists (map collectModules moduleNames);

    # Collect all home-manager modules from exports
    allHmModules = let
      # Get all exported module names except special ones
      moduleNames =
        builtins.filter
        (name: name != "all" && name != "defaults")
        (builtins.attrNames outputs.homeManagerModules);

      # For each export, check if it's a set (category) or a function (single module)
      collectModules = name: let
        export = outputs.homeManagerModules.${name};
        exportType = builtins.typeOf export;
      in
        if exportType == "set"
        then lib.attrsets.mapAttrsToList (_: value: value) export # It's a category
        else [export]; # It's a single module
    in
      builtins.concatLists (map collectModules moduleNames);

    # Create home-manager sharedModules configuration
    # Only applies if home-manager is enabled (options exist)
    hmSharedModulesConfig = {
      config,
      options,
      ...
    }: {
      config = lib.mkIf (builtins.hasAttr "home-manager" options) {
        home-manager.sharedModules = allHmModules;
      };
    };

    # Build a single nixos configuration
    mkHostConfig = hostName: hostConfig: let
      # Use provided path or default to hostsPath/<hostName>
      hostPath = hostConfig.path or (hostsPath + "/${hostName}");
    in
      nixpkgs.lib.nixosSystem {
        modules =
          (shared.modules or [])
          ++ allNixosModules
          ++ [hmSharedModulesConfig]
          ++ (presetsToModules (hostConfig.presets or []))
          ++ [
            hostPath
            {
              nixpkgs.hostPlatform.system = hostConfig.system;
            }
          ];
        specialArgs =
          specialArgs
          // (shared.specialArgs or {})
          // {hostName = hostName;};
      };

    # Build configurations for all hosts
    configs = nixpkgs.lib.mapAttrs mkHostConfig hosts;
  in
    configs;
}
