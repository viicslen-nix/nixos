{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
with lib; let
  cfg = config.features.theming;
  defaultWallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/c68a508b95baa0fcd99117f2da2a0f66eb208bbf/wallpapers/nix-wallpaper-nineish-dark-gray.svg";
    sha256 = "sha256-r+2MyWWfr7f3kzmsPI24hReScVaJtdmGO0drISs1NGM=";
  };
  plymouthLogo = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/f84c13adae08e860a7c3f76ab3a9bef916d276cc/logo/nix-snowflake-colours.svg";
    sha256 = "pHYa+d5f6MAaY8xWd3lDjhagS+nvwDL3w7zSsQyqH7A=";
  };
in {
  imports = [
    inputs.base16.nixosModule
    inputs.stylix.nixosModules.stylix
  ];

  options.features.theming = {
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
  };

  config = mkIf cfg.enable {
    stylix = {
      base16Scheme = config.scheme;

      image = cfg.wallpaper;
      polarity = cfg.polarity;

      fonts = {
        monospace = {
          package = pkgs.nerdfonts.override {fonts = ["FiraCode"];};
          name = "Fira Code Nerd Font";
        };
      };

      cursor = {
        name = "Adwaita";
        size = 24;
      };

      targets = {
        gnome.enable = true;

        plymouth.logo = plymouthLogo;

        chromium.enable = false;
      };
    };
  };
}
