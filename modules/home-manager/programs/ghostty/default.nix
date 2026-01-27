{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "ghostty";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      installVimSyntax = true;
      installBatSyntax = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
      package = pkgs.inputs.ghostty.default;
      settings = {
        auto-update = "off";

        adjust-cell-height = "60%";

        window-padding-y = 0;
        window-padding-color = "extend";
        window-padding-balance = true;

        window-theme = "auto";
        window-inherit-working-directory = false;

        confirm-close-surface = "always";

        background-opacity = 0.85;
        background-opacity-cells = 0.75;
        background-blur = true;

        gtk-adwaita = true;
        adw-toolbar-style = "raised-border";

        keybind = [
          "ctrl+shift+q=close_surface"
          "ctrl+shift+w=toggle_window_decorations"
        ];
      };
    };

    dconf.settings."org/gnome/shell/extensions/blur-my-shell/applications" = {
      whitelist = ["com.mitchellh.ghostty"];
    };
  };
}
