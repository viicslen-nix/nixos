_: {
  shared = {
    users = {
      neoscode = {
        description = "Victor R";
        password = "$6$hl2eKy3qKB3A7hd8$8QMfyUJst4sRAM9e9R4XZ/IrQ8qyza9NDgxRbo0VAUpAD.hlwi0sOJD73/N15akN9YeB41MJYoAE9O53Kqmzx/";
      };
    };
  };

  hosts = {
    wsl = {
      system = "x86_64-linux";
      presets = ["base" "dev" "work" "personal" "homelab"];
    };

    dostov-dev = {
      system = "x86_64-linux";
      presets = ["base" "desktop" "dev" "work" "personal" "homelab"];
    };

    home-desktop = {
      system = "x86_64-linux";
      presets = ["base" "desktop" "dev" "work" "personal" "homelab"];
    };

    asus-zephyrus-gu603 = {
      system = "x86_64-linux";
      presets = ["base" "desktop" "dev" "work" "personal" "homelab"];
    };

    lenovo-legion-go = {
      system = "x86_64-linux";
      presets = ["base" "desktop"];
    };

    openclaw = {
      kind = "home";
      user = "root";
      system = "x86_64-linux";
      presets = ["ai"];
    };
  };
}
