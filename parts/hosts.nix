# NixOS configurations for all hosts. The host list and the presets each host
# receives are declared in ../hosts/default.nix.
{
  inputs,
  nixosModuleTree,
  homeModuleTree,
  ...
}: {
  flake.nixosConfigurations =
    inputs.viicslen-lib.lib.hosts.mkNixosConfigurations {
      inherit inputs;
      # Feed hosts.nix the raw module trees rather than the flake-parts
      # normalised `self.outputs.{nixosModules,homeManagerModules}`.
      outputs =
        inputs.self.outputs
        // {
          nixosModules = nixosModuleTree;
          homeManagerModules = homeModuleTree;
        };
    }
    ../hosts;
}
