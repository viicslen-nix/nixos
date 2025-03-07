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

  shared = {
    modules = [
      outputs.nixosModules.all
      outputs.homeManagerModules.all
    ];

    specialArgs = {
      inherit inputs outputs;

      users = {
        neoscode = {
          description = "Victor R";
          password = "$6$hl2eKy3qKB3A7hd8$8QMfyUJst4sRAM9e9R4XZ/IrQ8qyza9NDgxRbo0VAUpAD.hlwi0sOJD73/N15akN9YeB41MJYoAE9O53Kqmzx/";
        };
      };
    };
  };
}
