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
      default = inputs.hyprland.packages.${pkgs.system}.hyprland;
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

  imports = [
    inputs.hyprland.nixosModules.default
  ];

  config = mkIf cfg.enable (mkMerge [
    {
      programs = {
        hyprland = {
          enable = true;
          xwayland.enable = true;
          package = inputs.hyprland.packages.${pkgs.system}.hyprland;
          portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
        };
      };

      xdg.portal = {
        enable = true;
        wlr.enable = true;
        config = {
          common = {
            default = [
              "hyprland"
              "xdph"
              "gtk"
            ];
            "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
            # "org.freedesktop.portal.FileChooser" = [ "xdg-desktop-portal-gtk" ];
          };
        };
        # extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
      };

      security.polkit.enable = true;
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.gdm.enableGnomeKeyring = true;

      environment.variables.XDG_RUNTIME_DIR = "/run/user/$UID";

      environment.systemPackages = with pkgs; [
        kdePackages.polkit-kde-agent-1
        pavucontrol
        qpwgraph

        # wallpaper
        swww
        waypaper

        # screenshot
        grim
        slurp
        inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
        satty

        # clipboard
        wl-clipboard
        cliphist

        # utils
        pkgs.inputs.pyprland.pyprland
        wl-screenrec
        wlr-randr
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

            ./config/settings.nix
            ./config/rules.nix
            ./config/binds.nix

            ./hyprlock.nix
            ./hypridle.nix
            ./pyprland.nix

            ./wlogout

            # ./swaync.nix
            # ./rofi.nix
            # ./waybar
            ./ags
          ];

          xdg.desktopEntries."org.gnome.Settings" = {
            name = "Settings";
            comment = "Gnome Control Center";
            icon = "org.gnome.Settings";
            exec = "env XDG_CURRENT_DESKTOP=gnome ${pkgs.gnome-control-center}/bin/gnome-control-center";
            categories = ["X-Preferences"];
            terminal = false;
          };

          wayland.windowManager.hyprland = {
            enable = true;

            systemd.variables = ["--all"];

            plugins = [
              inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
            ];
          };

          # make stuff work on wayland
          home.sessionVariables = {
            QT_QPA_PLATFORM = "wayland";
            SDL_VIDEODRIVER = "wayland";
            XDG_SESSION_TYPE = "wayland";
          };

          dconf.settings."org/gnome/desktop/wm/preferences".button-layout = ":";
        };
      };
    })
  ]);
}
