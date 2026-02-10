{
  lib,
  config,
  ...
}:
with lib; let
  name = "btop";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    programs.btop = {
      enable = true;
      settings = {
        vim_keys = true;
        theme_background = false;
        shown_boxes = "cpu mem proc";
        proc_sorting = "memory";
      };
    };
  };
}
