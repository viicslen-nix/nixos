{
  pkgs,
  ...
}: let
  pipewireStatus = import ./scripts/pipewire.nix {inherit pkgs;};
  mullvadStatus = import ./scripts/mullvad.nix {inherit pkgs;};
in {
    # Enable Network and Bluetooth Applet
    services.network-manager-applet.enable = true;
    services.blueman-applet.enable = true;

    # Configure Hyprland
    wayland.windowManager.hyprland.settings = {
      exec-once = [
        "killall -q waybar;sleep .5 && waybar"
      ];

      bind = [
        # "$mod CTRL SHIFT, R, exec, killall -q waybar;sleep .5 && waybar"
      ];
    };

    # Configure & Theme Waybar
    programs.waybar = {
      enable = true;
      package = pkgs.waybar;
      settings = [
        {
          layer = "top";
          position = "top";
          modules-center = ["hyprland/workspaces"];
          modules-left = [
            "custom/startmenu"
            "cpu"
            "memory"
            "custom/vpn"
            "hyprland/window"
            "idle_inhibitor"
          ];
          modules-right = [
            "tray"
            "wireplumber"
            "backlight"
            "battery"
            "custom/notification"
            "clock"
            "custom/exit"
          ];

          "hyprland/workspaces" = {
            format = "{name}";
            format-icons = {
              "active" = "";
              "default" = "";
            };
            on-scroll-up = "hyprctl dispatch workspace e+1";
            on-scroll-down = "hyprctl dispatch workspace e-1";
          };
          "clock" = {
            format = ''  {:L%I:%M %p}'';
            tooltip = true;
            tooltip-format = "<big>{:%A, %d.%B %Y }</big>\n<tt><small>{calendar}</small></tt>";
          };
          "hyprland/window" = {
            max-length = 22;
            separate-outputs = false;
          };
          "memory" = {
            interval = 5;
            format = " {}%";
            tooltip = true;
          };
          "cpu" = {
            interval = 5;
            format = " {usage:2}%";
            tooltip = true;
          };
          "disk" = {
            format = " {free}";
            tooltip = true;
          };
          "network" = {
            format-icons = [
              "󰤯"
              "󰤟"
              "󰤢"
              "󰤥"
              "󰤨"
            ];
            format-ethernet = " {bandwidthDownOctets}";
            format-wifi = "{icon} {signalStrength}%";
            format-disconnected = "󰤮";
            tooltip = false;
          };
          "tray" = {
            spacing = 12;
          };
          "custom/exit" = {
            tooltip = false;
            format = " ";
            on-click = "sleep 0.1 && wlogout";
          };
          "custom/startmenu" = {
            tooltip = false;
            format = "";
            on-click = "sleep 0.1 && rofi -show drun";
          };
          "custom/pipewire" = {
            tooltip = false;
            max-length = 6;
            exec = pipewireStatus.outPath;
            on-click-right = "pavucontrol";
          };
          "wireplumber" = {
            format = "{icon} {volume}%";
            format-muted = "  ";
            format-icons = ["" " " " "];
            on-click = "pypr toggle volume";
          };
          "custom/vpn" = {
            format = "VPN {}";
            tooltip = true;
            tooltip-exec = "mullvad status";
            exec = mullvadStatus.outPath;
            on-click = "mullvad connect";
            on-click-right = "mullvad disconnect";
            on-click-middle = "mullvad reconnect";
          };
          "idle_inhibitor" = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "󰾫";
            };
            tooltip = "true";
          };
          "custom/notification" = {
            tooltip = false;
            format = "{icon} {}";
            format-icons = {
              notification = "<span foreground='red'><sup></sup></span>";
              none = "";
              dnd-notification = "<span foreground='red'><sup></sup></span>";
              dnd-none = " ";
              inhibited-notification = "<span foreground='red'><sup></sup></span>";
              inhibited-none = " ";
              dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
              dnd-inhibited-none = " ";
            };
            return-type = "json";
            exec-if = "which swaync-client";
            exec = "swaync-client -swb";
            on-click = "sleep 0.1 && swaync-client -t";
            escape = true;
          };
          "battery" = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󱘖 {capacity}%";
            format-icons = [
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
            on-click = "";
            tooltip = false;
          };
          "backlight" = {
            device = "intel_backlight";
            format = "{icon} {percent}%";
            format-icons = ["" ""];
          };
          "privacy" = {
            icon-spacing = 1;
            icon-size = 12;
            transition-duration = 250;
            modules = [
              {type = "audio-in";}
              {type = "screenshare";}
            ];
          };
        }
      ];
      style = (builtins.unsafeDiscardStringContext (builtins.readFile ./style.css));
    };
  }
