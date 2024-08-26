# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{lib, ...}:
with lib.hm.gvariant; {
  dconf.settings = {
    # Apps and Keybindings
    "org/gnome/shell" = {
      favorite-apps = ["org.gnome.Nautilus.desktop" "microsoft-edge.desktop" "phpstorm.desktop" "kitty.desktop" "slack.desktop"];
    };

    "org/gnome/shell/keybindings" = {
      screenshot = ["<Shift><Alt><Super>s"];
      screenshot-window = ["<Control><Alt><Super>s"];
      show-screen-recording-ui = ["<Shift><Super>r"];
      show-screenshot-ui = ["<Shift><Super>s"];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = ["/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"];
      screenreader = [];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Shift><Control>space";
      command = "1password --quick-access";
      name = "1Password";
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
      whitelist = ["kitty"];
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
      menu-button-border-color = mkTuple [true "transparent"];
      menu-button-border-radius = mkTuple [true 10];
      menu-button-icon = "Distro_Icon";
      multi-monitor = true;
      runner-hotkey = ["<Control>Super_L"];
    };
  };

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/http" = "microsoft-edge.desktop";
    "x-scheme-handler/https" = "microsoft-edge.desktop";
  };
}
