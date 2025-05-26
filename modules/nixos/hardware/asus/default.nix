{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "asus";
  namespace = "hardware";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      asusctl
      supergfxctl
    ];

    services = {
      supergfxd = {
        enable = true;
        settings = {
          vfio_enable = true;
          vfio_save = true;
          always_reboot = true;
          hotplug_type = "Asus";
        };
      };

      asusd = {
        enable = true;
        enableUserService = true;
      };
    };
  };
}
