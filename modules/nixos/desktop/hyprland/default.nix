{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
with lib; let
  name = "hyprland";
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

    users = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "The users to configure hyprland for";
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
          withUWSM = true;
          xwayland.enable = true;
          package = pkgs.inputs.hyprland.hyprland;
          portalPackage = pkgs.inputs.hyprland.xdg-desktop-portal-hyprland;
        };

        dconf.enable = true;
        seahorse.enable = true;
      };

      xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal
        ];
        configPackages = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-hyprland
          xdg-desktop-portal
        ];
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
      };

      # Enable configure security
      security = {
        polkit.enable = true;
        pam.services.gdm.enableGnomeKeyring = true;
      };

      # Enable reequired services
      services = {
        blueman.enable = true;

        gnome = {
          gnome-keyring.enable = true;
          gnome-remote-desktop.enable = true;
          gnome-settings-daemon.enable = true;
        };
      };

      environment = {
        variables.XDG_RUNTIME_DIR = "/run/user/$UID";

        systemPackages = with pkgs; [
          polkit_gnome
          gnome-remote-desktop
          gnome-network-displays
          qpwgraph

          # Audio
          pavucontrol
          pwvucontrol
          wireplumber

          # wallpaper
          swww
          waypaper
          hyprpaper

          # screenshot
          grim
          slurp
          pkgs.inputs.hyprland-contrib.grimblast
          satty

          # clipboard
          wl-clipboard
          cliphist

          # utils
          networkmanagerapplet # needed for nm-applet icons
          pkgs.inputs.pyprland.pyprland
          wl-screenrec
          wlr-randr
          wlroots
        ];
      };

      nix.settings = {
        substituters = [
          "https://hyprland.cachix.org"
        ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };
    }
    (mkIf homeManagerLoaded {
      home-manager.users = lib.genAttrs cfg.users (_user: {
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
          systemd.enable = false;
          package = pkgs.inputs.hyprland.hyprland;
        };

        dconf.settings."org/gnome/desktop/wm/preferences".button-layout = ":";
      });
    })
  ]);
}
