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

        adjust-cell-height = "40%";

        window-padding-y = 0;
        window-padding-color = "extend";
        window-padding-balance = true;

        window-theme = "auto";
        window-inherit-working-directory = false;

        confirm-close-surface = "always";

        background-blur = true;

        gtk-toolbar-style = "raised-border";
        gtk-titlebar-style = "tabs";
        gtk-tabs-location = "bottom";

        keybind = [
          "ctrl+shift+q=close_surface"
          "ctrl+shift+w=toggle_window_decorations"
          "shift+enter=text:\\x1b\\r"
        ];

        custom-shader-animation = "always";

        custom-shader = [
          (pkgs.fetchFromGitHub {
            owner = "sahaj-b";
            repo = "ghostty-cursor-shaders";
            rev = "4faa83e4b9306750fc8de64b38c6f53c57862db8";
            sha256 = "sha256-ruhEqXnWRCYdX5mRczpY3rj1DTdxyY3BoN9pdlDOKrE=";
          } + "/cursor_warp.glsl")
        ];
      };
    };

    dconf.settings."org/gnome/shell/extensions/blur-my-shell/applications" = {
      whitelist = ["com.mitchellh.ghostty"];
    };
  };
}
