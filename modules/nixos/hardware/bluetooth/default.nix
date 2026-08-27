{
  flake.modules.nixos.bluetooth = {
    lib,
    config,
    ...
  }:
    with lib; let
      name = "bluetooth";
      namespace = "hardware";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);
      };

      config = mkIf cfg.enable {
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings = {
            General = {
              ControllerMode = "dual";
              FastConnectable = "true";
            };
            Policy = {
              AutoEnable = "true";
            };
          };
        };
      };
    };
}
