{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
with lib; let
  name = "theming";
  namespace = "functionality";

  cfg = config.modules.${namespace}.${name};

  homeManagerLoaded = builtins.hasAttr "home-manager" options;

  defaultWallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/JaKooLit/Wallpaper-Bank/c06358ea75720b6e9d3c779677c7dcf76576fb42/wallpapers/Lofi-Urban-Nightscape.png";
    sha256 = "sha256-YfHrEWLRomDRDbyboXNccMYKOuMY1JjHVczp3qb8U1c=";
  };
  plymouthLogo = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/f84c13adae08e860a7c3f76ab3a9bef916d276cc/logo/nix-snowflake-colours.svg";
    sha256 = "pHYa+d5f6MAaY8xWd3lDjhagS+nvwDL3w7zSsQyqH7A=";
  };

  # Function to create disabled targets attribute set
  createDisabledTargets = targetsList: stylixOptions: let
    # Helper function to check if a nested path exists in stylix options
    hasStylixTarget = path: stylixOptions: let
      pathList = lib.splitString "." path;
      checkPath = opts: pathSegments:
        if pathSegments == []
        then true
        else if builtins.hasAttr (builtins.head pathSegments) opts
        then checkPath (builtins.getAttr (builtins.head pathSegments) opts) (builtins.tail pathSegments)
        else false;
    in
      checkPath stylixOptions pathList;

    # Filter targets that exist in stylix options
    validTargets = builtins.filter (target: hasStylixTarget target stylixOptions) targetsList;

    # Helper function to create nested attribute set
    setAttrPath = path: value: let
      pathList = lib.splitString "." path;
      createNested = segments:
        if builtins.length segments == 1
        then {${builtins.head segments} = value;}
        else {${builtins.head segments} = createNested (builtins.tail segments);};
    in
      createNested pathList;

    # Create attribute sets for each valid target
    targetAttrs = map (target: setAttrPath "${target}.enable" false) validTargets;
  in
    # Merge all target attribute sets
    lib.foldl lib.recursiveUpdate {} targetAttrs;
in {
  imports = [
    inputs.base16.nixosModule
    inputs.stylix.nixosModules.stylix
  ];

  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "theming");

    polarity = mkOption {
      type = types.str;
      default = "dark";
      description = "The polarity of the theme";
    };

    wallpaper = mkOption {
      type = types.path;
      default = defaultWallpaper;
      description = "The wallpaper to use";
    };

    scheme = mkOption {
      type = types.path;
      default = "${inputs.tt-schemes}/base16/material-darker.yaml";
      description = "The base16 scheme to use";
    };

    disabledTargets = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of targets to disable in the theming module";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      scheme = {
        yaml = cfg.scheme;
        use-ifd = "always";
      };

      stylix = {
        enable = true;
        base16Scheme = cfg.scheme;

        image = cfg.wallpaper;
        polarity = cfg.polarity;

        cursor = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = mkDefault 24;
        };

        fonts = {
          monospace = {
            package = pkgs.nerd-fonts.fira-mono;
            name = "Fira Code Mono Nerd Font";
          };
        };

        opacity = {
          popups = 0.7;
          desktop = 0.3;
          terminal = 0.7;
          applications = 0.9;
        };

        targets = lib.recursiveUpdate {
          grub.useWallpaper = true;
          plymouth.logo = plymouthLogo;
          nvf.transparentBackground = true;
        } (createDisabledTargets cfg.disabledTargets options.stylix.targets or {});
      };
    }
    (mkIf homeManagerLoaded {
      home-manager.sharedModules = [
        ({options, ...}: {
          home.pointerCursor.enable = true;

          stylix = {
            enable = true;
            targets = lib.recursiveUpdate {
              qt.platform = "qtct";
              firefox.profileNames = ["default"];
              zen-browser.profileNames = ["default"];
              nvf.transparentBackground = true;
            } (createDisabledTargets cfg.disabledTargets options.stylix.targets or {});
          };

          gtk = {
            gtk3.extraConfig = {
              gtk-application-prefer-dark-theme = 1;
            };
            gtk4.extraConfig = {
              gtk-application-prefer-dark-theme = 1;
            };
          };
        })
      ];
    })
  ]);
}
