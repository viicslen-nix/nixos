{
  inputs,
  outputs,
}: {
  additionalClasses = {
    wsl = "nixos";
  };

  hosts = {
    wsl = {
      class = "wsl";
      arch = "x86_64";
      path = ./wsl;
    };

    asus-zephyrus-gu603 = {
      class = "nixos";
      arch = "x86_64";
      path = ./asus-zephyrus-gu603;
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
