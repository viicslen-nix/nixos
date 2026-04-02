{inputs, self, ...}: let
  vlib = inputs.viicslen-lib.lib;
in {
  systems = import inputs.systems;

  flake = {
    lib = vlib;

    formatter = vlib.pkgFromSystem "alejandra";

    devShells = vlib.genSystems (system:
      import ../dev-shells {
        inherit inputs system;
        pkgs = vlib.pkgsFor system;
      });

    packages = vlib.genSystems (system:
      inputs.nixpkgs.lib.packagesFromDirectoryRecursive {
        callPackage = vlib.callPackageForSystem system;
        directory = ../packages/by-name;
      });

    overlays = import ../overlays {inherit inputs;};

    nixosModules = vlib.modules.autoImportRecursive ../modules/nixos;

    homeManagerModules = vlib.modules.autoImportRecursive ../modules/home-manager;

    nixosConfigurations =
      vlib.hosts.mkNixosConfigurations {inherit inputs; outputs = self.outputs;} ../hosts;
  };
}
