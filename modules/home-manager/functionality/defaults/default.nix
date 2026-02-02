{
  lib,
  config,
  osConfig,
  ...
}:
with lib;
let
  name = "defaults";
  namespace = "functionality";

  cfg = config.modules.${namespace}.${name};

  # Helper to get the desktop file name from a package
  getDesktopFileName = pkg: (
    if pkg ? desktopItem && pkg.desktopItem ? name
    then "${pkg.desktopItem.name}.desktop"
    else if pkg ? pname
    then "${pkg.pname}.desktop"
    else null
  );
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
    {
      xdg.mimeApps.enable = true;
      xdg.configFile."mimeapps.list".force = true;
    }
    (mkIf (cfg.browser != null) {
      home = {
        sessionVariables.BROWSER = mkDefault (getExe cfg.browser);
        packages = [cfg.browser];
      };

      xdg.mimeApps.defaultApplications = let
        desktopFile = getDesktopFileName cfg.browser;
      in {
        "x-scheme-handler/http" = [desktopFile];
        "x-scheme-handler/https" = [desktopFile];
        "text/html" = [desktopFile];
      };
    })
    (mkIf (cfg.editor != null) {
      home = {
        sessionVariables.EDITOR = mkDefault (getExe cfg.editor);
        packages = [cfg.editor];
      };
      xdg.mimeApps.defaultApplications = let
          desktopFile = getDesktopFileName cfg.editor;
        in {
          "text/plain" = [desktopFile];
          "text/x-log" = [desktopFile];
          "text/x-script" = [desktopFile];
        };
    })
    (mkIf (cfg.terminal != null) {
      home = {
        sessionVariables.TERMINAL = mkDefault (getExe cfg.terminal);
        packages = [cfg.terminal];
      };
      xdg.mimeApps.defaultApplications = let
          desktopFile = getDesktopFileName cfg.terminal;
        in {
          "application/x-gnome-terminal" = [desktopFile];
          "application/x-terminal-emulator" = [desktopFile];
        };
    })
    (mkIf (cfg.fileManager != null) {
      home = {
        packages = [cfg.fileManager];
      };
      xdg.mimeApps.defaultApplications = let
          desktopFile = getDesktopFileName cfg.fileManager;
        in {
          "inode/directory" = [desktopFile];
        };
    })
    (mkIf (cfg.passwordManager != null) {
      home = {
        packages = [cfg.passwordManager];
      };
    })
  ];
}
