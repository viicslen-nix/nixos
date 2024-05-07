{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
with lib; let
  cfg = config.features.hyprland;
  homeManagerLoaded = builtins.hasAttr "home-manager" options;
in {
  options.features.hyprland = {
    enable = mkEnableOption (mdDoc "hyprland");

    user = mkOption {
      type = types.str;
      default = "nixos";
      description = "The user to configure hyprland for";
    };
  };

  imports = [
    inputs.hyprland.nixosModules.default
  ];

  config = mkIf cfg.enable (mkMerge [
    {
      programs = {
        hyprland = {
          enable = true;
          xwayland.enable = true;
        };

        waybar.enable = true;
      };

      environment.systemPackages = with pkgs; [
        inputs.anyrun.packages.${system}.anyrun
        swaynotificationcenter
        hyprpaper
        wlroots
      ];

      nix.settings = {
        substituters = [
          "https://hyprland.cachix.org"
          "https://anyrun.cachix.org"
          ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
        ];
      };
    }
    (mkIf homeManagerLoaded {
      home-manager = {
        users.${cfg.user} = {
          imports = [
            inputs.hyprland.homeManagerModules.default
            inputs.hyprlock.homeManagerModules.default
            ./hyprpaper.nix
            ./settings.nix
            ./hyprlock.nix
            ./hypridle.nix
            ./wlogout.nix
            ./anyrun.nix
            ./binds.nix
            ./rules.nix
            ./ags
          ];

          home.packages = with pkgs; [
            # screenshot
            grim
            slurp

            # utils
            # wl-ocr
            wl-clipboard
            wl-screenrec
            wlr-randr

            # Launchers
            inputs.walker.packages.${pkgs.system}.default 
            gtk4-layer-shell
            nwg-drawer
            wofi

            inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
          ];

          # make stuff work on wayland
          home.sessionVariables = {
            QT_QPA_PLATFORM = "wayland";
            SDL_VIDEODRIVER = "wayland";
            XDG_SESSION_TYPE = "wayland";
          };

          wayland.windowManager.hyprland.enable = true;
        };
      };
    })
  ]);
}
