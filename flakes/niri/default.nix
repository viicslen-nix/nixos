{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
with lib; let
  name = "niri";
  namespace = "desktop";

  cfg = config.modules.${namespace}.${name};

  homeManagerLoaded = builtins.hasAttr "home-manager" options;
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "niri");

    terminal = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        The default terminal emulator to use for niri keybinds.
        If null, will use the defaults module terminal if available.
      '';
    };

    browser = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        The default browser to use for niri keybinds.
        If null, will use the defaults module browser if available.
      '';
    };

    editor = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        The default editor to use for niri keybinds.
        If null, will use the defaults module editor if available.
      '';
    };

    fileManager = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        The default file manager to use for niri keybinds.
        If null, will use the defaults module fileManager if available.
      '';
    };

    passwordManager = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        The default password manager to use for niri keybinds.
        If null, will use the defaults module passwordManager if available.
      '';
    };
  };

  imports = [
    inputs.niri-flake.nixosModules.niri
  ];

  config = mkIf cfg.enable (mkMerge [
    {programs.niri.enable = true;}
    (mkIf homeManagerLoaded {
      home-manager.sharedModules = [
        ./rules.nix
        ./binds.nix
        ./settings.nix
        ./shell.nix
      ];
    })
  ]);
}
