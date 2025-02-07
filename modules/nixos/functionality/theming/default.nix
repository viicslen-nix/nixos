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

  defaultWallpaper = "${inputs.wallpapers}/wallpapers/Lofi-Urban-Nightscape.png";
  plymouthLogo = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/f84c13adae08e860a7c3f76ab3a9bef916d276cc/logo/nix-snowflake-colours.svg";
    sha256 = "pHYa+d5f6MAaY8xWd3lDjhagS+nvwDL3w7zSsQyqH7A=";
  };
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

        fonts = {
          monospace = {
            package = pkgs.nerd-fonts.fira-mono;
            name = "Fira Code Mono Nerd Font";
          };
        };

        cursor = {
          name = "Adwaita";
          size = 24;
        };

        opacity = {
          popups = 0.7;
          desktop = 0.3;
          terminal = 0.7;
          applications = 0.9;
        };

        targets = {
          qt.enable = false; # Will be themed with adwaita

          grub.useImage = true;
          plymouth.logo = plymouthLogo;
        };
      };

      environment.systemPackages = with pkgs; [
        adwaita-qt6
        adwaita-qt
      ];

      qt = {
        enable = true;
        platformTheme = "gnome";
        style = "adwaita-dark";
      };
    }
    (mkIf homeManagerLoaded {
      home-manager.sharedModules = [
        {
          stylix = {
            enable = true;

            targets = {
              qt.enable = false; # Will be themed with adwaita
            };
          };

          gtk = {
            gtk3.extraConfig = {
              gtk-application-prefer-dark-theme = 1;
            };
            gtk4.extraConfig = {
              gtk-application-prefer-dark-theme = 1;
            };
          };
          qt = {
            enable = true;
            style.name = mkForce "adwaita-dark";
            platformTheme.name = mkForce "adwaita";
          };
        }
      ];
    })
  ]);
}
