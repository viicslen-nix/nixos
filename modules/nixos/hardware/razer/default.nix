{
  flake.modules.nixos.razer = {
    lib,
    config,
    users,
    ...
  }:
    with lib; let
      name = "razer";
      namespace = "hardware";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);
      };

      config = mkIf cfg.enable {
        hardware.openrazer = {
          enable = true;
          users = attrNames users;
        };
        boot.extraModulePackages = with config.boot.kernelPackages; [openrazer];
      };
    };
}
