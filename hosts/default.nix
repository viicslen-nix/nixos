{inputs, outputs }: {
  hosts = {
    wsl = {
      arch = "x86_64";
      class = "nixos";
      path = ./hosts/wsl;
    };

    asus-zephyrus-gu603 = {
      arch = "x86_64";
      class = "nixos";
      path = ./hosts/asus-zephyrus-gu603;
    };
  };

  perClass = class: {
    modules = inputs.nixpkgs.lib.optionals (class == "nixos") [
      outputs.nixosModules.default
    ];
  };

  shared = {
    modules = [
      outputs.nixosModules.default
      outputs.homeManagerModules.default
    ];

    specialArgs = {inherit inputs outputs;};
  };
}
