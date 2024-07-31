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
            "hyprland/window"
            "idle_inhibitor"
          ];
          modules-right = [
            "tray"
            "custom/pipewire"
            "custom/vpn"
            "battery"
            "custom/notification"
            "clock"
            "custom/exit"
          ];

          "hyprland/workspaces" = {
            format = "{name}";
            format-icons = {
              default = " ";
              active = " ";
              urgent = " ";
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
            on-click = "pavucontrol";
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
        }
      ];
      style = ''
        * {
          font-size: 14px;
          border-radius: 0px;
          border: none;
          font-family: JetBrainsMono Nerd Font;
          min-height: 0px;
        }
        window#waybar {
          background-color: #${colorScheme.base00};
        }
        window#waybar.empty #window {
          background: none;
        }
        #workspaces {
          color: #${colorScheme.base00};
          background: #${colorScheme.base01};
          margin: 4px 4px;
          padding: 5px;
          border-radius: 16px;
        }
        #workspaces button {
          font-weight: bold;
          padding: 0px 5px;
          margin: 0px 3px;
          border-radius: 16px;
          color: #${colorScheme.base00};
          background: linear-gradient(45deg, #${colorScheme.base0E}, #${colorScheme.base0F}, #${colorScheme.base0D}, #${colorScheme.base09});
          background-size: 300% 300%;
          opacity: 0.5;
          transition: ${betterTransition};
        }
        #workspaces button.active {
          opacity: 1.0;
          min-width: 40px;
        }
        #workspaces button:hover {
          opacity: 0.8;
        }
        #custom-startmenu {
          color: #${colorScheme.base0D};
          background: #${colorScheme.base01};
          font-size: 28px;
          margin: 0px;
          padding: 0px 30px 0px 15px;
          border-radius: 0px 0px 40px 0px;
        }
        #custom-exit {
          font-weight: bold;
          color: #${colorScheme.base00};
          background: linear-gradient(45deg, #${colorScheme.base0C}, #${colorScheme.base0F}, #${colorScheme.base0B}, #${colorScheme.base08});
          background-size: 300% 300%;
          margin: 0px;
          padding: 0px 15px 0px 30px;
          border-radius: 0px 0px 0px 40px;
        }
        #window, #cpu, #memory, #idle_inhibitor {
          font-weight: bold;
          margin: 4px 0px;
          margin-left: 7px;
          padding: 0px 18px;
          color: #${colorScheme.base05};
          background: #${colorScheme.base01};
          border-radius: 24px 10px 24px 10px;
        }
        #network, #battery, #pulseaudio, #tray, #clock,
        #custom-notification, #custom-pipewire, #custom-vpn {
          font-weight: bold;
          background: #${colorScheme.base01};
          color: #${colorScheme.base05};
          margin: 4px 0px;
          margin-right: 7px;
          border-radius: 10px 24px 10px 24px;
          padding: 0px 18px;
        }
        tooltip {
          background: #${colorScheme.base00};
          border: 1px solid #${colorScheme.base0E};
          border-radius: 12px;
        }
        tooltip label {
          color: #${colorScheme.base07};
        }
        @keyframes gradient_horizontal {
          0% {
            background-position: 0% 50%;
          }
          50% {
            background-position: 100% 50%;
          }
          100% {
            background-position: 0% 50%;
          }
        }
        @keyframes swiping {
          0% {
            background-position: 0% 200%;
          }
          100% {
            background-position: 200% 200%;
          }
        }
      '';
    };
  }
