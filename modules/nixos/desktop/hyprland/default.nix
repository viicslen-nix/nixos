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

    gnomeCompatibility = mkOption {
      type = types.bool;
      default = false;
    };
  };

  imports = [
    # inputs.hyprland.nixosModules.default
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
        seahorse.enable = mkIf cfg.gnomeCompatibility true;
      };

      xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = with pkgs; [
          kdePackages.xdg-desktop-portal-kde
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
          xdg-desktop-portal
        ];
        configPackages = with pkgs; [
          xdg-desktop-portal-hyprland
          kdePackages.xdg-desktop-portal-kde
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
          xdg-desktop-portal
        ];
        config = {
          common = {
            default = [
              "hyprland"
              "gnome"
              "xdph"
              "kde"
              "gtk"
            ];
            "org.freedesktop.impl.portal.FileChooser" = if cfg.gnomeCompatibility then ["xdg-desktop-portal-gtk"] else ["kde"];
          };
        };
      };

      # Enable configure security
      security = {
        polkit.enable = true;
        pam.services.gdm.enableGnomeKeyring = mkIf cfg.gnomeCompatibility true;
      };

      # Enable reequired services
      services = {
        blueman.enable = true;

        gnome = mkIf cfg.gnomeCompatibility {
          gnome-keyring.enable = true;
          gnome-remote-desktop.enable = true;
          gnome-settings-daemon.enable = true;
        };
      };

      environment = {
        variables.XDG_RUNTIME_DIR = "/run/user/$UID";

        systemPackages = with pkgs; [
          hyprpolkitagent
          polkit_gnome
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
          # networkmanagerapplet # needed for nm-applet icons
          pkgs.inputs.pyprland.pyprland
          wl-screenrec
          wlr-randr
          wlroots
        ];
      };

      nixpkgs.overlays = [
        inputs.hyprpanel.overlay
      ];

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
      home-manager.sharedModules = [
        {
          imports = [
            inputs.hyprland.homeManagerModules.default
            ./config
            ./components
          ];

          wayland.windowManager.hyprland = {
            enable = true;
            package = null;
            portalPackage = null;
            systemd.enable = false;
          };

          services.hyprpolkitagent.enable = cfg.gnomeCompatibility == false;

          xdg.desktopEntries."org.gnome.Settings" = mkIf cfg.gnomeCompatibility {
            name = "Settings";
            comment = "Gnome Control Center";
            icon = "org.gnome.Settings";
            exec = "env XDG_CURRENT_DESKTOP=gnome ${pkgs.gnome-control-center}/bin/gnome-control-center";
            categories = ["X-Preferences"];
            terminal = false;
          };

          dconf.settings."org/gnome/desktop/wm/preferences".button-layout = ":";
        }
      ];
    })
  ]);
}
