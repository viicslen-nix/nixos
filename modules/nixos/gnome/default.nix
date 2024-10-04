{
  lib,
  pkgs,
  config,
  options,
  ...
}:
with lib; let
  cfg = config.features.gnome;
  homeManagerLoaded = builtins.hasAttr "home-manager" options;
  defaultExtensions = [
    pkgs.gnomeExtensions.appindicator
    pkgs.gnomeExtensions.blur-my-shell
    pkgs.gnomeExtensions.dash-to-panel
    pkgs.gnomeExtensions.arcmenu
    pkgs.gnomeExtensions.user-themes
    pkgs.gnomeExtensions.autohide-battery
    pkgs.gnomeExtensions.supergfxctl-gex
    pkgs.gnomeExtensions.caffeine
    pkgs.gnomeExtensions.gsconnect
    pkgs.gnomeExtensions.arrange-windows
    pkgs.gnomeExtensions.rounded-corners
    pkgs.gnomeExtensions.astra-monitor
  ];
  enabledExtensions = cfg.additionalExtensions ++ defaultExtensions;
in {
  options.features.gnome = {
    enable = mkEnableOption (mdDoc "gnome");

    user = mkOption {
      type = types.str;
      default = "nixos";
      description = "The user update the settings for";
    };

    enableGdm = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable the GDM window manager";
    };

    exclude = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        gnome-tour
        gnome-music
        gnome-remote-desktop
        cheese # webcam tool
        epiphany # web browser
        tali # poker game
        iagno # go game
        hitori # sudoku game
        atomix # puzzle game
      ];
      description = "List of packages to exclude from default gnome install";
    };

    additionalExtensions = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "List of extensions to install and enable";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Enable the GNOME Desktop Environment.
      services.xserver.enable = mkDefault true;
      services.xserver.desktopManager.gnome.enable = true;

      # Enable the GNOME Display Manager
      services.xserver.displayManager.gdm = mkIf cfg.enableGdm {
        enable = true;
      };

      # Exclude GNOME applications from the default install
      environment.gnome.excludePackages = cfg.exclude;

      # Enable GNOME services
      services.gnome.core-shell.enable = true;
      services.gnome.core-utilities.enable = true;
      services.gnome.core-os-services.enable = true;

      # Install GNOME Tweaks
      environment.systemPackages = with pkgs;
        [
          adw-gtk3
          gnome-tweaks
          adwaita-icon-theme
        ]
        ++ enabledExtensions;

      # Required for some GNOME extensions
      environment.variables = {
        GI_TYPELIB_PATH = "/run/current-system/sw/lib/girepository-1.0";
      };
    }
    (mkIf homeManagerLoaded {
      home-manager.users.${cfg.user} = {
        gtk.enable = true;
        gtk.iconTheme.name = "Adwaita";
        gtk.iconTheme.package = pkgs.adwaita-icon-theme;

        dconf.settings = {
          "org/gtk/settings/file-chooser".clock-format = "12h";
          "org/gnome/shell/app-switcher".current-workspace-only = true;
          "org/gnome/settings-daemon/plugins/media-keys".screenreader = [];
          "org/gnome/desktop/wm/preferences".button-layout = lib.mkDefault ":minimize,maximize,close";
          "org/gnome/desktop/interface" = {
            clock-format = "12h";
            color-scheme = "prefer-dark";
          };
          "org/gnome/mutter" = {
            dynamic-workspaces = true;
            experimental-features = ["scale-monitor-framebuffer"];
          };
          "org/gnome/shell" = {
            disable-user-extensions = false;
            enabled-extensions = lists.forEach enabledExtensions (x: x.extensionUuid);
          };
          "org/gnome/shell/keybindings" = {
            screenshot = ["<Shift><Alt><Super>s"];
            screenshot-window = ["<Control><Alt><Super>s"];
            show-screen-recording-ui = ["<Shift><Super>r"];
            show-screenshot-ui = ["<Shift><Super>s"];
          };

          # Extensions
          "org/gnome/shell/extensions/lennart-k/rounded_corners" = {
            corner-radius = 7;
          };

          "org/gnome/shell/extensions/caffeine" = {
            indicator-position-max = 3;
            toggle-state = true;
            user-enabled = true;
          };

          "org/gnome/shell/extensions/astra-monitor" = {
            network-header-show = false;
            storage-header-show = false;
          };

          "org/gnome/shell/extensions/blur-my-shell/applications" = {
            blur = true;
            dynamic-opacity = false;
          };

          "org/gnome/shell/extensions/arcmenu" = {
            arcmenu-hotkey = [];
            button-padding = 10;
            custom-menu-button-icon-size = 30.0;
            distro-icon = 22;
            menu-button-appearance = "Icon";
            menu-button-icon = "Distro_Icon";
            multi-monitor = true;
            runner-hotkey = ["<Control>Super_L"];
          };

          "org/gnome/shell/extensions/dash-to-panel" = {
            dot-color-dominant = true;
            dot-color-override = false;
            focus-highlight-dominant = true;
            hide-overview-on-startup = true;
            isolate-monitors = true;
            isolate-workspaces = true;
            overview-click-to-exit = true;
            trans-use-custom-opacity = true;
            trans-use-dynamic-opacity = true;
            panel-element-positions = ''
              {
                "0": [
                  {
                    "element": "showAppsButton",
                    "visible": false,
                    "position": "stackedTL"
                  },
                  {
                    "element": "activitiesButton",
                    "visible": false,
                    "position": "stackedTL"
                  },
                  {
                    "element": "leftBox",
                    "visible": true,
                    "position": "stackedTL"
                  },
                  {
                    "element": "taskbar",
                    "visible": true,
                    "position": "stackedTL"
                  },
                  {
                    "element": "centerBox",
                    "visible": true,
                    "position": "stackedBR"
                  },
                  {
                    "element": "rightBox",
                    "visible": true,
                    "position": "stackedBR"
                  },
                  {
                    "element": "dateMenu",
                    "visible": true,
                    "position": "stackedBR"
                  },
                  {
                    "element": "systemMenu",
                    "visible": true,
                    "position": "stackedBR"
                  },
                  {
                    "element": "desktopButton",
                    "visible": true,
                    "position": "stackedBR"
                  }
                ],
                "1": [
                  {
                    "element": "showAppsButton",
                    "visible": false,
                    "position": "stackedTL"
                  },
                  {
                    "element": "activitiesButton",
                    "visible": false,
                    "position": "stackedTL"
                  },
                  {
                    "element": "leftBox",
                    "visible": true,
                    "position": "stackedTL"
                  },
                  {
                    "element": "taskbar",
                    "visible": true,
                    "position": "stackedTL"
                  },
                  {
                    "element": "centerBox",
                    "visible": true,
                    "position": "stackedBR"
                  },
                  {
                    "element": "rightBox",
                    "visible": true,
                    "position": "stackedBR"
                  },
                  {
                    "element": "dateMenu",
                    "visible": true,
                    "position": "stackedBR"
                  },
                  {
                    "element": "systemMenu",
                    "visible": true,
                    "position": "stackedBR"
                  },
                  {
                    "element": "desktopButton",
                    "visible": true,
                    "position": "stackedBR"
                  }
                ]
              }
            '';
          };
        };
      };
    })
  ]);
}
