{
  inputs,
  outputs,
}: {
  shared = {
    modules = [
      outputs.nixosModules.all
      outputs.homeManagerModules.all
      { system.stateVersion = "25.11"; }
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

  hosts = {
    wsl = {
      system = "x86_64-linux";
      path = ./wsl;
    };

    dostov-dev = {
      system = "x86_64-linux";
      path = ./dostov-dev;
    };

    asus-zephyrus-gu603 = {
      system = "x86_64-linux";
      path = ./asus-zephyrus-gu603;
    };

    lenovo-legion-go = {
      system = "x86_64-linux";
      path = ./lenovo-legion-go;
    };
  };
}
