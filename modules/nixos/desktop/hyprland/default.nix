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
  stylixCursorSizeSet =
    builtins.hasAttr "stylix" config
    && builtins.hasAttr "cursor" config.stylix
    && builtins.hasAttr "size" config.stylix.cursor;
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

    hyprVariables = mkOption {
      type = types.attrsOf types.str;
      default = {
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
        XCURSOR_SIZE = mkIf stylixCursorSizeSet (builtins.toString config.stylix.cursor.size);
      };
    };

    globalVariables = mkOption {
      type = types.attrsOf types.str;
      default = {
        # Allow unfree packages
        NIXPKGS_ALLOW_UNFREE = "1";

        # Wayland environment
        XDG_SESSION_TYPE = "wayland";
        CLUTTER_BACKEND = "wayland";
        GDK_BACKEND = "wayland,x11";
        SDL_VIDEODRIVER = "wayland";
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
      };
    };

    extraGlobalVariables = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Extra global variables to set";
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
          # package = pkgs.inputs.hyprland.hyprland;
          # portalPackage = pkgs.inputs.hyprland.xdg-desktop-portal-hyprland;
        };

        dconf.enable = true;
        hyprlock.enable = true;
        seahorse.enable = mkIf cfg.gnomeCompatibility true;
      };

      xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = with pkgs; [
          # kdePackages.xdg-desktop-portal-kde
          xdg-desktop-portal-hyprland
          # xdg-desktop-portal-shana
          xdg-desktop-portal-gtk
          # xdg-desktop-portal-gnome
          xdg-desktop-portal
        ];
        configPackages = with pkgs; [
          # kdePackages.xdg-desktop-portal-kde
          xdg-desktop-portal-hyprland
          # xdg-desktop-portal-shana
          xdg-desktop-portal-gtk
          # xdg-desktop-portal-gnome
          xdg-desktop-portal
        ];
        # config = {
        #   common = {
        #     default = [
        #       "hyprland"
        #       "gnome"
        #       "xdph"
        #       "gtk"
        #       "kde"
        #     ];
        #     "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
        #     "org.freedesktop.impl.portal.FileChooser" = mkIf (cfg.gnomeCompatibility == false) ["kde"];
        #   };
        #   hyprland = {
        #     default = [
        #       "hyprland"
        #       "xdph"
        #       "gtk"
        #     ];
        #     "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
        #     "org.freedesktop.impl.portal.FileChooser" = mkIf (cfg.gnomeCompatibility == false) ["kde"];
        #   };
        # };
      };

      # Enable configure security
      security = {
        polkit.enable = true;
        pam.services.gdm.enableGnomeKeyring = mkIf cfg.gnomeCompatibility true;
      };

      # Enable reequired services
      services = {
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
          waypaper
          hyprpaper

          # screenshot
          grim
          slurp
          flameshot
          pkgs.inputs.hyprland-contrib.grimblast
          satty

          # clipboard
          wl-clipboard
          cliphist

          # utils
          # networkmanagerapplet # needed for nm-applet icons
          pkgs.inputs.pyprland.pyprland
          wl-screenrec
          wl-clipboard
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
