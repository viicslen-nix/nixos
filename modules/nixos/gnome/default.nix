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
      environment.gnome.excludePackages =
        (with pkgs; [
          gnome-tour
        ])
        ++ (with pkgs.gnome; [
          gnome-music
          tali # poker game
          iagno # go game
          hitori # sudoku game
          atomix # puzzle game
          gnome-remote-desktop
        ]);

      # Enable DConf to tweak desktop settings
      programs.dconf.enable = true;

      # Enable Seahorse to manage keyring
      programs.seahorse.enable = true;

      services.udev.packages = with pkgs; [gnome.gnome-settings-daemon];

      # Install GNOME Tweaks
      environment.systemPackages = with pkgs; [
        adw-gtk3
        gnome-tweaks
        adwaita-icon-theme
        gnomeExtensions.appindicator
        gnomeExtensions.blur-my-shell
        gnomeExtensions.dash-to-panel
        gnomeExtensions.arcmenu
        gnomeExtensions.user-themes
        gnomeExtensions.autohide-battery
        gnomeExtensions.supergfxctl-gex
        gnomeExtensions.solaar-extension
        gnomeExtensions.caffeine
        gnomeExtensions.gsconnect
        gnomeExtensions.forge
        gnomeExtensions.arrange-windows
        gnomeExtensions.rounded-corners
        gnomeExtensions.tophat
        gnomeExtensions.simple-break-reminder

        # TopHat Dependencies
        gtop
        libgtop
        clutter
        clutter-gtk
      ];

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
          "org/gnome/mutter".experimental-features = ["scale-monitor-framebuffer"];
          "org/gnome/desktop/interface".color-scheme = "prefer-dark";
          "org/gnome/desktop/wm/preferences".button-layout = lib.mkDefault ":minimize,maximize,close";
        };
      };
    })
  ]);
}
