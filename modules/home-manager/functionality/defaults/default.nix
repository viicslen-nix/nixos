{
  lib,
  config,
  osConfig,
  ...
}:
with lib; let
  name = "defaults";
  namespace = "functionality";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    browser = mkOption {
      type = types.package;
      default = null;
      description = ''
        The default web browser to use. This will set the `BROWSER` environment
        variable and configure `xdg-open` to use this browser.
      '';
    };
    editor = mkOption {
      type = types.package;
      default = null;
      description = ''
        The default text editor to use. This will set the `EDITOR` and `VISUAL`
        environment variables.
      '';
    };
    terminal = mkOption {
      type = types.package;
      default = null;
      description = ''
        The default terminal emulator to use. This will set the `TERMINAL`
        environment variable.
      '';
    };
  };

  config = {
    home = {
      sessionVariables = {
        BROWSER = mkIf (cfg.browser != null) (toString cfg.browser);
        EDITOR = mkIf (cfg.editor != null) (toString cfg.editor);
        TERMINAL = mkIf (cfg.terminal != null) (toString cfg.terminal);
      };

      packages =
        mkIf (cfg.editor != null) [cfg.editor]
        ++ mkIf (cfg.browser != null) [cfg.browser]
        ++ mkIf (cfg.terminal != null) [cfg.terminal];
    };

    xdg.configFile."mimeapps.list" = {
      text = mkIf (cfg.browser != null) ''
        [Default Applications]
        x-scheme-handler/http=${cfg.browser.pname}.desktop
        x-scheme-handler/https=${cfg.browser.pname}.desktop
        text/html=${cfg.browser.pname}.desktop
      '';
    };

    wayland.windowManager.hyprland.settings = {
      "$editor" = mkIf (cfg.editor != null) toString cfg.editor;
      "$browser" = mkIf (cfg.browser != null) toString cfg.browser;
      "$terminal" = mkIf (cfg.terminal != null) toString cfg.terminal;
    };
  };
}
