{
  flake.nixosModules.razer =
{
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
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    hardware.openrazer = {
      enable = true;
      users = attrNames users;
    };
    boot.extraModulePackages = with config.boot.kernelPackages; [openrazer];
  };
}
  ;
}
