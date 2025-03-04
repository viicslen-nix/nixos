{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "qmk";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      via
      keymapviz
      qmk
      qmk_hid
    ];

    services.udev.packages = [pkgs.via];

    hardware.keyboard.qmk.enable = true;

    services.udev.extraRules = mkAfter ''
      # Configuration of VIA compatible keyboards
      ${(builtins.unsafeDiscardStringContext (builtins.readFile ./qmk.rules))}
    '';
  };
}
