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

    package = mkOption {
      type = types.package;
      default = pkgs.hyprland;
      description = "The hyprland package to use";
    };

    user = mkOption {
      type = types.str;
      default = "nixos";
      description = "The user to configure hyprland for";
    };

    palette = mkOption {
      type = types.attrsOf types.str;
      default = {};
    };

    gnomeCompatibility = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs = {
        hyprland = {
          enable = true;
          xwayland.enable = true;
          package = cfg.package;
        };
      };

      xdg.portal = {
        enable = true;
        wlr.enable = true;
      };

      security.pam.services.gdm.enableGnomeKeyring = cfg.gnomeCompatibility;
      environment.variables.XDG_RUNTIME_DIR = "/run/user/$UID";

      environment.systemPackages = with pkgs; [
        swaynotificationcenter
        networkmanagerapplet
        pavucontrol
        qpwgraph

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
            ./config/settings.nix
            ./config/rules.nix
            ./config/binds.nix

            ./hyprpaper.nix
            ./hyprlock.nix
            ./hypridle.nix

            ./swaync.nix
            ./rofi.nix
            ./wlogout
            ./waybar
          ];

          wayland.windowManager.hyprland = {
            systemd.variables = ["--all"];

            plugins = [
              inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
            ];
          };

          home.packages = with pkgs; [
            # screenshot
            grim
            slurp

            # utils
            wl-clipboard
            wl-screenrec
            wlr-randr

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
