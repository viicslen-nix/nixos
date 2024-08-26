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
      default = [
        pkgs.gnome-tour
        pkgs.gnome.gnome-music
        pkgs.gnome.tali # poker game
        pkgs.gnome.iagno # go game
        pkgs.gnome.hitori # sudoku game
        pkgs.gnome.atomix # puzzle game
        pkgs.gnome.gnome-remote-desktop
      ];
      description = "List of packages to exclude from default gnome install";
    };

    extensions = mkOption {
      type = types.listOf types.package;
      default = [
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
      description = "List of extensions to install and enable";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Enable the GNOME Desktop Environment.
      services.xserver.enable = lib.mkDefault true;
      services.xserver.desktopManager.gnome.enable = true;

      services.xserver.displayManager.gdm = mkIf cfg.enableGdm {
        enable = true;
      };

      # Enable GNOME Keyring
      services.gnome.gnome-keyring.enable = true;

      # Exclude GNOME applications from the default install
      environment.gnome.excludePackages = cfg.exclude;

      # Enable DConf to tweak desktop settings
      programs.dconf.enable = true;

      # Enable Seahorse to manage keyring
      programs.seahorse.enable = true;

      services.udev.packages = with pkgs; [gnome.gnome-settings-daemon];

      # Install GNOME Tweaks
      environment.systemPackages = with pkgs;
        [
          adw-gtk3
          gnome-tweaks
          adwaita-icon-theme
        ]
        ++ cfg.extensions;

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

        dconf.settings = with lib.hm.gvariant; {
          "org/gtk/settings/file-chooser".clock-format = "12h";
          "org/gnome/shell/app-switcher".current-workspace-only = true;
          "org/gnome/desktop/interface".color-scheme = "prefer-dark";
          "org/gnome/desktop/wm/preferences".button-layout = lib.mkDefault ":minimize,maximize,close";
          "org/gnome/mutter" = {
            dynamic-workspaces = true;
            experimental-features = ["scale-monitor-framebuffer"];
          };
          "org/gnome/shell" = {
            disable-user-extensions = false;
            enabled-extensions = lists.forEach cfg.extensions (x: x.extensionUuid);
          };

          # Extensions
          "org/gnome/shell/extensions/lennart-k/rounded_corners" = {
            corner-radius = 7;
          };

          "org/gnome/shell/extensions/astra-monitor" = {
            network-header-show = false;
            storage-header-show = false;
          };

          "org/gnome/shell/extensions/blur-my-shell/applications" = {
            blur = true;
            dynamic-opacity = false;
            whitelist = [ "kitty" ];
          };

          "org/gnome/shell/extensions/dash-to-panel" = {
            dot-color-dominant = true;
            dot-color-override = false;
            focus-highlight-dominant = true;
            hide-overview-on-startup = true;
            isolate-monitors = true;
            isolate-workspaces = true;
            overview-click-to-exit = true;
            panel-element-positions = ''
              {"0":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}],"1":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}
            '';
            trans-use-custom-opacity = true;
            trans-use-dynamic-opacity = true;
          };

          "org/gnome/shell/extensions/arcmenu" = {
            arcmenu-hotkey = [];
            button-padding = 10;
            custom-menu-button-icon-size = 30.0;
            distro-icon = 22;
            menu-button-appearance = "Icon";
            menu-button-border-color = mkTuple [ true "transparent" ];
            menu-button-border-radius = mkTuple [ true 10 ];
            menu-button-icon = "Distro_Icon";
            multi-monitor = true;
            runner-hotkey = [ "<Control>Super_L" ];
          };
        };
      };
    })
  ]);
}
