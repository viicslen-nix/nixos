{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
with lib; let
  name = "gnome";
  namespace = "desktop";

  cfg = config.modules.${namespace}.${name};

  homeManagerLoaded = builtins.hasAttr "home-manager" options;
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "hyprland");

    package = mkOption {
      type = types.package;
      default = pkgs.inputs.hyprland.hyprland;
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
          package = pkgs.inputs.hyprland.hyprland;
          portalPackage = pkgs.inputs.hyprland.xdg-desktop-portal-hyprland;
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
            "org.freedesktop.portal.FileChooser" = ["xdg-desktop-portal-gtk"];
          };
        };
        # extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
      };

      # Enable the GNOME Services
      programs.dconf.enable = true;
      security.polkit.enable = true;
      programs.seahorse.enable = true;
      services.gnome.gnome-keyring.enable = true;
      services.gnome.gnome-remote-desktop.enable = true;
      services.gnome.gnome-settings-daemon.enable = true;
      security.pam.services.gdm.enableGnomeKeyring = true;

      environment.variables.XDG_RUNTIME_DIR = "/run/user/$UID";

      environment.systemPackages = with pkgs; [
        polkit_gnome
        gnome-remote-desktop
        gnome-network-displays
        pavucontrol
        qpwgraph

        # wallpaper
        swww
        waypaper

        # screenshot
        grim
        slurp
        pkgs.inputs.hyprland-contrib.grimblast
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
            ./config
            ./components
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
            package = pkgs.inputs.hyprland.hyprland;
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
