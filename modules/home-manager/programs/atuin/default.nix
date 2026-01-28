{
  lib,
  config,
  inputs,
  ...
}:
with lib;
with inputs.self.lib; let
  name = "atuin";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.atuin = {
        enable = true;

        settings = {
          workspaces = true;
          inline_height = 0;
          keymap_mode = "vim-normal";
          filter_mode_shell_up_key_binding = "session";
        };
      };
    }
    (persistence.mkPersistence config {
      share = ["atuin"];
      cache = ["atuin"];
    })
  ]);
}
