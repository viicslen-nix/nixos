# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    # General Settings
    "org/gnome/mutter" = {
      dynamic-workspaces = true;
    };

    "org/gtk/settings/file-chooser" = {
      clock-format = "12h";
    };

    "org/gnome/shell/app-switcher" = {
      current-workspace-only = true;
    };


    # Apps and Keybindings
    "org/gnome/shell" = {
      favorite-apps = [ "org.gnome.Nautilus.desktop" "microsoft-edge.desktop" "phpstorm.desktop" "kitty.desktop" "slack.desktop" ];
    };

    "org/gnome/shell/keybindings" = {
      screenshot = [ "<Shift><Alt><Super>s" ];
      screenshot-window = [ "<Control><Alt><Super>s" ];
      show-screen-recording-ui = [ "<Shift><Super>r" ];
      show-screenshot-ui = [ "<Shift><Super>s" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [ "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" ];
      screenreader = [];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Shift><Control>space";
      command = "1password --quick-access";
      name = "1Password";
    };

    
    # Extensions
    "org/gnome/shell/extensions/arcmenu" = {
      arcmenu-hotkey = [];
      button-padding = 10;
      custom-menu-button-icon-size = 30.0;
      distro-icon = 22;
      menu-background-color = "rgba(48,48,49,0.98)";
      menu-border-color = "rgb(60,60,60)";
      menu-button-appearance = "Icon";
      menu-button-border-color = mkTuple [ true "transparent" ];
      menu-button-border-radius = mkTuple [ true 10 ];
      menu-button-border-width = mkTuple [ false 3 ];
      menu-button-icon = "Distro_Icon";
      menu-foreground-color = "rgb(223,223,223)";
      menu-item-active-bg-color = "rgb(25,98,163)";
      menu-item-active-fg-color = "rgb(255,255,255)";
      menu-item-hover-bg-color = "rgb(21,83,158)";
      menu-item-hover-fg-color = "rgb(255,255,255)";
      menu-separator-color = "rgba(255,255,255,0.1)";
      multi-monitor = true;
      prefs-visible-page = 0;
      runner-hotkey = [ "<Control>Super_L" ];
      search-entry-border-radius = mkTuple [ true 25 ];
    };

    "org/gnome/shell/extensions/astra-monitor" = {
      gpu-indicators-order = "[\"icon\",\"activity bar\",\"activity graph\",\"activity percentage\",\"memory bar\",\"memory graph\",\"memory percentage\",\"memory value\"]";
      headers-height = 0;
      headers-height-override = 0;
      memory-indicators-order = "[\"icon\",\"bar\",\"graph\",\"percentage\",\"value\",\"free\"]";
      monitors-order = "[\"processor\",\"gpu\",\"memory\",\"storage\",\"network\",\"sensors\"]";
      network-header-show = false;
      network-indicators-order = "[\"icon\",\"IO bar\",\"IO graph\",\"IO speed\"]";
      processor-indicators-order = "[\"icon\",\"bar\",\"graph\",\"percentage\"]";
      processor-menu-gpu-color = "";
      profiles = ''
        {"default":{"panel-margin-left":0,"sensors-header-tooltip-sensor2-digits":-1,"memory-update":3,"gpu-header-memory-graph-color1":"rgba(29,172,214,1.0)","panel-box":"right","memory-header-show":true,"network-header-tooltip-io":true,"processor-header-bars-color2":"rgba(214,29,29,1.0)","processor-header-icon-size":18,"storage-source-storage-io":"auto","sensors-header-tooltip-sensor4-name":"","storage-header-icon-color":"","network-source-public-ipv4":"https://api.ipify.org","storage-header-io-graph-color2":"rgba(214,29,29,1.0)","storage-header-io":false,"processor-menu-top-processes-percentage-core":true,"sensors-header-sensor1":"\\"\\"","processor-header-graph":true,"storage-header-graph-width":30,"network-header-bars":false,"processor-source-load-avg":"auto","network-menu-arrow-color1":"rgba(29,172,214,1.0)","storage-header-io-graph-color1":"rgba(29,172,214,1.0)","gpu-header-icon":true,"processor-menu-graph-breakdown":true,"sensors-header-icon-custom":"","sensors-header-sensor2":"\\"\\"","network-header-icon-alert-color":"rgba(235, 64, 52, 1)","memory-header-tooltip-free":false,"storage-header-io-figures":2,"network-menu-arrow-color2":"rgba(214,29,29,1.0)","sensors-header-tooltip-sensor3-name":"","network-source-public-ipv6":"https://api6.ipify.org","monitors-order":"\\"\\"","network-header-graph":true,"network-indicators-order":"\\"\\"","memory-header-percentage":false,"processor-header-tooltip":true,"gpu-main":"\\"\\"","storage-header-bars":true,"sensors-header-tooltip-sensor5-digits":-1,"memory-menu-swap-color":"rgba(29,172,214,1.0)","storage-io-unit":"kB/s","memory-header-graph-width":30,"processor-header-graph-color1":"rgba(29,172,214,1.0)","storage-header-tooltip-value":false,"gpu-header-icon-custom":"","processor-header-graph-breakdown":true,"panel-margin-right":0,"gpu-header-icon-size":18,"processor-source-cpu-usage":"auto","sensors-header-tooltip-sensor3-digits":-1,"sensors-header-icon":true,"memory-header-value-figures":3,"processor-header-graph-color2":"rgba(214,29,29,1.0)","compact-mode":false,"panel-box-order":0,"compact-mode-compact-icon-custom":"","network-header-graph-width":30,"gpu-header-tooltip":true,"sensors-header-icon-alert-color":"rgba(235, 64, 52, 1)","gpu-header-activity-percentage-icon-alert-threshold":0,"sensors-header-sensor2-digits":-1,"sensors-header-tooltip-sensor2-name":"","sensors-update":3,"gpu-header-tooltip-memory-value":true,"processor-header-bars":false,"gpu-header-memory-bar-color1":"rgba(29,172,214,1.0)","gpu-header-tooltip-memory-percentage":true,"sensors-header-tooltip-sensor1":"\\"\\"","sensors-header-tooltip-sensor1-digits":-1,"storage-header-free-figures":3,"processor-header-percentage-core":false,"storage-main":"[default]","network-source-network-io":"auto","memory-header-bars":true,"processor-header-percentage":false,"sensors-header-icon-color":"","storage-header-io-threshold":0,"memory-header-graph-color1":"rgba(29,172,214,1.0)","compact-mode-activation":"both","storage-header-icon-size":18,"sensors-header-tooltip-sensor1-name":"","sensors-header-icon-size":18,"sensors-source":"auto","explicit-zero":false,"storage-header-percentage-icon-alert-threshold":0,"storage-header-tooltip-io":true,"sensors-header-tooltip-sensor2":"\\"\\"","compact-mode-expanded-icon-custom":"","memory-header-graph-color2":"rgba(29,172,214,0.3)","processor-header-icon-alert-color":"rgba(235, 64, 52, 1)","processor-header-tooltip-percentage":true,"gpu-header-show":false,"network-update":1.5,"sensors-header-tooltip-sensor3":"\\"\\"","storage-header-free-icon-alert-threshold":0,"memory-header-icon-custom":"","sensors-header-tooltip-sensor4":"\\"\\"","storage-header-percentage":false,"sensors-temperature-unit":"celsius","storage-header-icon-alert-color":"rgba(235, 64, 52, 1)","storage-menu-arrow-color2":"rgba(214,29,29,1.0)","memory-source-top-processes":"auto","storage-header-value-figures":3,"storage-header-io-bars-color1":"rgba(29,172,214,1.0)","storage-menu-arrow-color1":"rgba(29,172,214,1.0)","processor-header-graph-width":30,"network-header-icon-custom":"","gpu-header-tooltip-activity-percentage":true,"network-header-icon":true,"sensors-header-sensor2-layout":"vertical","sensors-header-tooltip-sensor5":"\\"\\"","memory-header-bars-breakdown":true,"sensors-header-show":false,"sensors-header-tooltip":false,"storage-update":3,"processor-header-bars-core":false,"storage-indicators-order":"\\"\\"","processor-menu-bars-breakdown":true,"storage-header-io-bars-color2":"rgba(214,29,29,1.0)","network-io-unit":"kB/s","storage-header-icon":true,"gpu-header-activity-graph-color1":"rgba(29,172,214,1.0)","memory-unit":"kB-kiB","processor-menu-core-bars-breakdown":true,"sensors-header-sensor2-show":false,"network-header-tooltip":true,"storage-header-tooltip-free":true,"storage-header-bars-color1":"rgba(29,172,214,1.0)","theme-style":"dark","storage-source-storage-usage":"auto","network-header-io":false,"memory-header-tooltip-percentage":true,"memory-indicators-order":"\\"\\"","memory-source-memory-usage":"auto","memory-header-graph-breakdown":false,"memory-header-tooltip-value":true,"memory-menu-graph-breakdown":true,"sensors-indicators-order":"\\"\\"","compact-mode-start-expanded":false,"startup-delay":2,"memory-header-percentage-icon-alert-threshold":0,"sensors-header-sensor1-show":false,"network-ignored-regex":"","memory-header-value":false,"memory-header-bars-color1":"rgba(29,172,214,1.0)","network-header-io-graph-color1":"rgba(29,172,214,1.0)","gpu-header-memory-bar":true,"memory-used":"total-free-buffers-cached","gpu-header-memory-graph-width":30,"gpu-header-memory-graph":false,"headers-font-family":"","memory-header-icon":true,"network-header-io-graph-color2":"rgba(214,29,29,1.0)","memory-header-bars-color2":"rgba(29,172,214,0.3)","processor-gpu":true,"network-header-icon-color":"","storage-header-value":false,"gpu-header-icon-alert-color":"rgba(235, 64, 52, 1)","processor-header-icon":true,"headers-font-size":0,"network-header-io-figures":2,"network-header-show":false,"storage-header-tooltip":true,"network-header-io-bars-color1":"rgba(29,172,214,1.0)","processor-update":1.5,"network-source-wireless":"auto","processor-indicators-order":"\\"\\"","storage-header-icon-custom":"","gpu-header-activity-bar":true,"gpu-header-activity-bar-color1":"rgba(29,172,214,1.0)","shell-bar-position":"top","network-ignored":"\\"[]\\"","network-header-io-bars-color2":"rgba(214,29,29,1.0)","memory-header-icon-color":"","sensors-header-sensor1-digits":-1,"storage-header-io-layout":"vertical","memory-header-icon-size":18,"network-header-io-threshold":0,"storage-header-show":false,"sensors-header-tooltip-sensor4-digits":-1,"processor-header-percentage-icon-alert-threshold":0,"memory-header-tooltip":true,"headers-height-override":0,"memory-header-graph":false,"network-header-icon-size":18,"gpu-header-icon-color":"","memory-header-free-figures":3,"storage-header-io-bars":false,"processor-header-bars-breakdown":true,"gpu-header-activity-graph":false,"storage-ignored":"\\"[]\\"","memory-header-icon-alert-color":"rgba(235, 64, 52, 1)","storage-header-free":false,"processor-header-icon-custom":"","gpu-header-memory-percentage":false,"processor-header-tooltip-percentage-core":false,"processor-source-cpu-cores-usage":"auto","processor-source-top-processes":"auto","processor-header-icon-color":"","sensors-header-tooltip-sensor5-name":"","gpu-header-activity-graph-width":30,"gpu-header-activity-percentage":false,"gpu-indicators-order":"\\"\\"","processor-header-bars-color1":"rgba(29,172,214,1.0)","gpu-update":1.5,"gpu-header-memory-percentage-icon-alert-threshold":0,"network-header-io-layout":"vertical","processor-header-show":true,"storage-header-graph":false,"memory-header-free-icon-alert-threshold":0,"storage-ignored-regex":"","storage-menu-device-color":"rgba(29,172,214,1.0)","storage-header-tooltip-percentage":true,"memory-header-free":false,"storage-source-top-processes":"auto"}}
      '';
      queued-pref-category = "";
      sensors-indicators-order = "[\"icon\",\"value\"]";
      storage-header-show = false;
      storage-indicators-order = "[\"icon\",\"bar\",\"percentage\",\"value\",\"free\",\"IO bar\",\"IO graph\",\"IO speed\"]";
      storage-main = "eui.0025384c314089f1-part1";
    };

    "org/gnome/shell/extensions/blur-my-shell/applications" = {
      blur = true;
      dynamic-opacity = false;
      whitelist = [ "kitty" ];
    };

    "org/gnome/shell/extensions/dash-to-panel" = {
      animate-appicon-hover = true;
      animate-appicon-hover-animation-convexity = {
        RIPPLE = 2.0;
        PLANK = 1.0;
        SIMPLE = 0.0;
      };
      animate-appicon-hover-animation-extent = {
        RIPPLE = 4;
        PLANK = 4;
        SIMPLE = 1;
      };
      animate-appicon-hover-animation-travel = {
        SIMPLE = 0.1;
        RIPPLE = 0.4;
        PLANK = 0.0;
      };
      animate-appicon-hover-animation-type = "SIMPLE";
      animate-appicon-hover-animation-zoom = {
        SIMPLE = 1.1;
        RIPPLE = 1.25;
        PLANK = 2.0;
      };
      appicon-margin = 8;
      appicon-padding = 4;
      available-monitors = [ 0 1 ];
      dot-color-dominant = true;
      dot-color-override = false;
      dot-position = "BOTTOM";
      focus-highlight-dominant = true;
      hide-overview-on-startup = true;
      hotkeys-overlay-combo = "TEMPORARILY";
      isolate-monitors = true;
      isolate-workspaces = true;
      leftbox-padding = -1;
      overview-click-to-exit = true;
      panel-anchors = ''
        {"0":"MIDDLE","1":"MIDDLE"}
      '';
      panel-element-positions = ''
        {"0":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}],"1":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}
      '';
      panel-lengths = ''
        {"0":100,"1":100}
      '';
      panel-sizes = ''
        {"0":48,"1":48}
      '';
      primary-monitor = 0;
      status-icon-padding = -1;
      trans-use-custom-opacity = true;
      trans-use-dynamic-opacity = true;
      tray-padding = -1;
      window-preview-title-position = "TOP";
    };
  };
}
