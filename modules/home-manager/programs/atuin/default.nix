{
  flake.modules.homeManager.atuin = {
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
        enable = mkEnabledOption (mdDoc name);
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

              # ponytail: ctrl-r/ctrl-s only exist in atuin's emacs keymap, so
              # vim-normal has no way to cycle filter/search mode. Re-add them.
              keymap.vim_normal = {
                "ctrl-r" = "cycle-filter-mode";
                "ctrl-s" = "cycle-search-mode";
              };
            };
          };
        }
        (persistence.mkPersistence config {
          share = ["atuin"];
          cache = ["atuin"];
        })
      ]);
    };
}
