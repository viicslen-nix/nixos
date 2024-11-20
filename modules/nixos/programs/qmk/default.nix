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

    hardware.keyboard.qmk.enable = true;

    # services.udev.extraRules = mkAfter ''
    #   # Configuration of VIA compatible keyboards
    #   # https://wiki.archlinux.org/title/Keyboard_input#Configuration_of_VIA_compatible_keyboards
    #   KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
    # ''
  };
}
