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
        theme_background = false;
        vim_keys = true;
        shown_boxes = "cpu mem net proc";
        proc_sorting = "memory";
      };
    };
  };
}
