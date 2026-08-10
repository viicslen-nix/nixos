{
  flake.modules.homeManager.herdr = {
    lib,
    config,
    ...
  }: let
    cfg = config.modules.programs.herdr;
  in {
    options.modules.programs.herdr.enable = lib.mkEnableOption "Herdr" // {default = true;};

    config.programs.herdr = lib.mkIf cfg.enable {
      enable = true;
      settings = {
        onboarding = false;
        keys = {
          prefix = "ctrl+space";
          workspace_picker = "prefix+w";
          detach = "prefix+d";
          reload_config = "prefix+r";
          open_notification_target = "prefix+shift+o";
          previous_workspace = "prefix+(";
          next_workspace = "prefix+)";
          rename_tab = "prefix+comma";
          previous_tab = [
            "prefix+p"
            "prefix+ctrl+p"
            "prefix+ctrl+h"
          ];
          next_tab = [
            "prefix+n"
            "prefix+ctrl+n"
            "prefix+ctrl+l"
          ];
          close_tab = "prefix+&";
          last_pane = "prefix+semicolon";
          cycle_pane_next = "prefix+o";
          split_vertical = "prefix+|";
          resize_mode = "prefix+shift+r";
        };
      };
    };
  };
}
