{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  name = "autostart";
  namespace = "home";

  cfg = config.${namespace}.${name};

  autostartType = types.either types.package (types.submodule {
    options = {
      package = mkOption {
        type = types.package;
        description = "The package to autostart";
      };
      args = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Arguments to pass to the application";
      };
    };
  });

  normalizeApp = app:
    if isDerivation app then {
      package = app;
      args = [];
    } else app;

  genDesktopEntryPath = app: let
    normalized = normalizeApp app;
    pkg = normalized.package;
    args = normalized.args;
    exePath = lib.getExe pkg;
    execLine = lib.escapeShellArgs ([exePath] ++ args);
    content =
      if pkg ? desktopItem
      then
        pkg.desktopItem.text
      else
        builtins.readFile (pkg + "/share/applications/" + pkg.pname + ".desktop");
    lines = lib.splitString "\n" content;
    modifiedLines = map (line:
      if lib.hasPrefix "Exec=" line
      then "Exec=${execLine}"
      else line
    ) lines;
    modifiedContent = lib.concatStringsSep "\n" modifiedLines;
  in
    pkgs.writeText "autostart-${pkg.pname}.desktop" modifiedContent;
in {
  options.${namespace}.${name} = mkOption {
    type = types.listOf autostartType;
    default = [];
    description = ''
      List of packages to create autostart entries for.
      Can be either a package directly or an object with {package, args}.
    '';
    example = lib.literalExpression ''
      [
        pkgs.mullvad-vpn
        {
          package = pkgs._1password-gui;
          args = ["--silent"];
        }
      ]
    '';
  };

  config = {
    xdg.autostart = mkIf (cfg != []) {
      enable = true;
      entries = map genDesktopEntryPath cfg;
    };
  };
}
