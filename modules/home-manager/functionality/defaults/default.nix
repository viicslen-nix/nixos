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
      type = types.nullOr types.package;
      default = null;
      description = ''
        The default web browser to use. This will set the `BROWSER` environment
        variable and configure `xdg-open` to use this browser.
      '';
    };
    editor = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        The default text editor to use. This will set the `EDITOR` and `VISUAL`
        environment variables.
      '';
    };
    terminal = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        The default terminal emulator to use. This will set the `TERMINAL`
        environment variable.
      '';
    };
    fileManager = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        The default file manager to use.
      '';
    };
    passwordManager = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        The default password manager to use.
      '';
    };
  };

  config = mkMerge [
    {xdg.configFile."mimeapps.list".force = true;}
    (mkIf (cfg.browser != null) {
      home = {
        sessionVariables.BROWSER = mkDefault (getExe cfg.browser);
        packages = [cfg.browser];
      };
      xdg.configFile."mimeapps.list" = {
        text = ''
          [Default Applications]
          x-scheme-handler/http=${cfg.browser.pname}.desktop
          x-scheme-handler/https=${cfg.browser.pname}.desktop
          text/html=${cfg.browser.pname}.desktop
        '';
      };
    })
    (mkIf (cfg.editor != null) {
      home = {
        sessionVariables.EDITOR = mkDefault (getExe cfg.editor);
        packages = [cfg.editor];
      };
    })
    (mkIf (cfg.terminal != null) {
      home = {
        sessionVariables.TERMINAL = mkDefault (getExe cfg.terminal);
        packages = [cfg.terminal];
      };
    })
    (mkIf (cfg.fileManager != null) {
      home = {
        packages = [cfg.fileManager];
      };
    })
    (mkIf (cfg.passwordManager != null) {
      home = {
        packages = [cfg.passwordManager];
      };
    })
  ];
}
