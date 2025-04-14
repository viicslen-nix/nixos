# *.nix
{ inputs, ... }:
{
  imports = [ inputs.hyprpanel.homeManagerModules.hyprpanel ];

  wayland.windowManager.hyprland.settings.layerrule = [
    "blur, ^(gjs)$"
    "blur, ^(bar-0)$"
    "blur, ^(bar-1)$"
    "blurpopups, ^(gjs)$"
    "blurpopups, ^(bar-0)$"
    "blurpopups, ^(bar-1)$"
    "ignorealpha 0.2, ^(gjs)$"
    "ignorealpha 0.2, ^(bar-0)$"
    "ignorealpha 0.2, ^(bar-1)$"
  ];

  programs.hyprpanel = {

    # Enable the module.
    # Default: false
    enable = true;

    # Automatically restart HyprPanel with systemd.
    # Useful when updating your config so that you
    # don't need to manually restart it.
    # Default: false
    systemd.enable = true;

    # Add '/nix/store/.../hyprpanel' to your
    # Hyprland config 'exec-once'.
    # Default: false
    hyprland.enable = true;

    # Fix the overwrite issue with HyprPanel.
    # See below for more information.
    # Default: false
    overwrite.enable = true;

    # Configure and theme almost all options from the GUI.
    # Options that require '{}' or '[]' are not yet implemented,
    # except for the layout above.
    # See 'https://hyprpanel.com/configuration/settings.html'.
    # Default: <same as gui>
    settings = {
      tear = true;
      menus.dashboard.stats.enable_gpu = true;

      bar = {
        clock.format = "%a %b %d  %I:%M %p";
        launcher.autoDetectIcon = true;

        workspaces = {
          ignored = "-\\d+";
          show_icons = true;
          show_numbered = false;
          showWsIcons = true;
          showApplicationIcons = true;
          workspaceIconMap = {};
        };
      };

      theme = {
        font.size = "1.2rem";

        osd.scaling = 80;
        notification.scaling = 90;

        bar = {
          scaling = 70;
          opacity = 60;
          transparent = true;
          outer_spacing = "0.8em";
          buttons.background_opacity = 85;

          menus = {
            opacity = 90;
            popover.scaling = 80;

            menu = {
              power.scaling = 90;
              clock.scaling = 70;
              media.scaling = 70;
              volume.scaling = 80;
              network.scaling = 85;
              battery.scaling = 70;
              bluetooth.scaling = 70;
              dashboard.scaling = 70;
              notifications.scaling =  85;
            };
          };
        };
      };

      # Configure bar layouts for monitors.
      # See 'https://hyprpanel.com/configuration/panel.html'.
      # Default: null
      layout = {
        "bar.layouts" = {
          "0" = {
            "left" = [
              "launcher"
              "dashboard"
              "workspaces"
              "windowtitle"
              "hypridle"
              "submap"
            ];
            "middle" = [
              "cpu"
              "ram"
              "storage"
            ];
            "right" = [
              "volume"
              "network"
              "systray"
              "clock"
              "notifications"
              "power"
            ];
          };
          "1" = {
            "left" = [
              "dashboard"
              "workspaces"
              "windowtitle"
            ];
            "middle" = [];
            "right" = [
              "volume"
              "clock"
              "notifications"
            ];
          };
        };
      };
    };
  };
}
