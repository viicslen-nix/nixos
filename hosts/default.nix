{
  inputs,
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

  shared = {
    modules = [
      ../modules/nixos/imports.nix
      ../modules/home-manager/imports.nix
    ];

    specialArgs = {inherit inputs;};
  };
}
