{
  pkgs,
  config,
  lib,
  host,
  ...
}: let
  betterTransition = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";
  colorScheme = config.lib.stylix.colors;
  pipewireStatus = import ./scripts/pipewire.nix {inherit pkgs;};
  mullvadStatus = import ./scripts/mullvad.nix {inherit pkgs;};
in
  with lib; {
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
      style = let
        workspaceRadius = "16px";
        moduleBackground = "@base01";
      in ''
        * {
          font-size: 14px;
          border-radius: 0px;
          border: none;
          font-family: JetBrainsMono Nerd Font;
          min-height: 0px;
        }
        window#waybar {
          background-color: transparent;
        }
        window#waybar.empty #window {
          background: none;
          padding: 0px;
        }
        tooltip {
          background: ${moduleBackground};
          border: 1px solid @base0E;
          border-radius: 12px;
        }
        tooltip label {
          color: @base07;
        }

        #workspaces {
          color: @base00;
          background: ${moduleBackground};
          margin: 4px 4px;
          padding: 5px;
          border-radius: ${workspaceRadius};
        }
        #workspaces button {
          font-weight: bold;
          padding: 0px 5px;
          margin: 0px 3px;
          border-radius: ${workspaceRadius};
          color: @base00;
          background: linear-gradient(45deg, @base0E, @base0F, @base0D, @base09);
          background-size: 300% 300%;
          opacity: 0.5;
        }
        #workspaces button.active {
          opacity: 1.0;
          min-width: 40px;
          border-bottom: none;
        }
        #workspaces button:hover {
          opacity: 0.8;
        }
        .modules-left #workspaces button {
            border-bottom: 0 solid transparent;
        }
        .modules-left #workspaces button.focused,
        .modules-left #workspaces button.active {
            border-bottom: 0 solid @base05;
        }
        .modules-center #workspaces button {
            border-bottom: 0 solid transparent;
        }
        .modules-center #workspaces button.focused,
        .modules-center #workspaces button.active {
            border-bottom: 0 solid @base05;
        }
        .modules-right #workspaces button {
            border-bottom: 0 solid transparent;
        }
        .modules-right #workspaces button.focused,
        .modules-right #workspaces button.active {
            border-bottom: 0 solid @base05;
        }

        #custom-startmenu {
          color: @base0D;
          background: ${moduleBackground};
          font-size: 24px;
          margin: 0px;
          padding: 0px 35px 0px 15px;
          border-radius: 0px 0px 40px 0px;
        }
        #custom-exit {
          font-weight: bold;
          color: @base00;
          background: linear-gradient(45deg, @base0C, @base0F, @base0B, @base08);
          background-size: 300% 300%;
          margin: 0px;
          padding: 0px 15px 0px 30px;
          border-radius: 0px 0px 0px 40px;
        }

        #window, #cpu, #memory, #idle_inhibitor, #custom-vpn {
          font-weight: bold;
          margin: 4px 0px;
          margin-left: 7px;
          padding: 0px 18px;
          color: @base05;
          background: ${moduleBackground};
          border-radius: 24px 10px 24px 10px;
        }
        #network, #battery, #pulseaudio, #tray, #clock,
        #custom-notification, #custom-pipewire, #wireplumber, #backlight {
          font-weight: bold;
          background: ${moduleBackground};
          color: @base05;
          margin: 4px 0px;
          margin-right: 7px;
          border-radius: 10px 24px 10px 24px;
          padding: 0px 18px;
        }
      '';
    };

    # Enable Network Manager Applet
    services.network-manager-applet.enable = true;

    # Configure Hyprland
    wayland.windowManager.hyprland.settings = {
      "$launcher" = "${pkgs.rofi-wayland}/bin/rofi -show drun";

      exec-once = [
        "killall -q waybar;sleep .5 && waybar"
        "nm-applet --indicator"
      ];

      bind = [
        "$mod SHIFT, W, exec, killall -q waybar;sleep .5 && waybar"
      ];
    };
  }
