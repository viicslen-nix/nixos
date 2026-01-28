{...}: {
  # Generate nixosConfigurations from host definitions
  mkNixosConfigurations = {
    hostsPath, # Base path to hosts directory (e.g., ./hosts)
    inputs, # Flake inputs (for passing to hosts/default.nix)
    outputs, # Flake outputs (for passing to hosts/default.nix)
  }: let
    nixpkgs = inputs.nixpkgs;

    # Import hosts configuration (shared and hosts definitions)
    hostsConfig = import hostsPath {inherit inputs outputs;};
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

    # Build a single nixos configuration
    mkHostConfig = hostName: hostConfig: let
      # Use provided path or default to hostsPath/<hostName>
      hostPath = hostConfig.path or (hostsPath + "/${hostName}");
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
