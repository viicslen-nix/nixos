{
  lib,
  config,
  ...
}:
with lib; let
  name = "atuin";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "atuin");
  };

  config.programs.atuin = mkIf cfg.enable {
    enable = true;

    settings = {
      keymap_mode = "vim-insert";
    };
  };
}