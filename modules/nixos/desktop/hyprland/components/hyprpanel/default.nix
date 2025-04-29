# *.nix
{inputs, ...}: {
  imports = [inputs.hyprpanel.homeManagerModules.hyprpanel];

  wayland.windowManager.hyprland.settings = {
    layerrule = [
      "blur, .*menu$"
      "blur, ^(bar-[0-9])$"
      "blurpopups, ^(bar-[0-9])$"
      "blurpopups, .*menu$"
      "ignorealpha 0.2, ^(bar-[0-9])$"
      "ignorealpha 0.2, .*menu$"
    ];

    bind = [
      "$mod CTRL SHIFT, R, exec, hyprpanel restart"
    ];
  };

  programs.hyprpanel = {
    # Enable the module.
    # Default: false
    enable = true;

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
      scalingPriority = "both";
      menus.dashboard.stats.enable_gpu = true;
      menus.dashboard.directories.enabled = false;
      menus.clock.weather.location = "Miami, FL";

      bar = {
        clock.format = "%a %b %d  %I:%M %p";
        launcher.autoDetectIcon = true;

        workspaces = {
          ignored = "-\\d+";
          show_icons = true;
          show_numbered = false;
          showWsIcons = true;
          showApplicationIcons = true;
        };
      };

      theme = {
        font.size = "1.05rem";

        osd.scaling = 80;
        notification.scaling = 90;

        bar = {
          scaling = 70;
          opacity = 30;
          outer_spacing = "0.8em";
          buttons.background_opacity = 90;

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
              bluetooth.scaling = 85;
              dashboard.scaling = 70;
              notifications.scaling = 85;
            };
          };
        };
      };
    };
  };
}
