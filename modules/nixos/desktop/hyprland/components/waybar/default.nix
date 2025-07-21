{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pipewireStatus = import ./scripts/pipewire.nix {inherit pkgs;};
  mullvadStatus = import ./scripts/mullvad.nix {inherit pkgs;};
in {
  # Enable Network and Bluetooth Applet
  # services.network-manager-applet.enable = true;
  # services.blueman-applet.enable = true;

  # Configure Hyprland
  wayland.windowManager.hyprland.settings.layerrule = [
    "blur, ^(waybar)$"
    "blurpopups, ^(waybar)$"
    "ignorealpha 0.2, ^(waybar)$"
  ];

  # Disable Stylix Theme
  stylix.targets.waybar.enable = false;

  # Configure & Theme Waybar
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    package = pkgs.inputs.waybar.waybar;
    settings = [
      {
        layer = "top";
        position = "top";
        modules-center = [
          "clock"
        ];
        modules-left = [
          "custom/startmenu"
          "hyprland/workspaces"
          "hyprland/window"
          "hyprland/submap"
          "custom/screenshot"
          "idle_inhibitor"
        ];
        modules-right = [
          "privacy"
          "tray"
          "group/resources"
          "group/system"
          "custom/notification"
          "custom/exit"
        ];

        "group/resources" = {
          orientation = "horizontal";
          modules = [
            "cpu"
            "memory"
          ];
        };

        "group/system" = {
          orientation = "horizontal";
          modules = [
            "custom/vpn"
            "network"
            "bluetooth"
            "wireplumber"
            "backlight"
            "battery"
          ];
        };

        "hyprland/workspaces" = {
          format = "{name}";
          format-icons = {
            "active" = "";
            "default" = "";
          };
          on-scroll-up = "hyprctl dispatch split:workspace e-1";
          on-scroll-down = "hyprctl dispatch split:workspace e+1";
        };
        "clock" = {
          format = ''{:L%I:%M %p}'';
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
          tooltip = true;
          format-icons = [
            "󰤯 "
            "󰤟 "
            "󰤢 "
            "󰤥 "
            "󰤨 "
          ];
          format-ethernet = "󰈀 ";
          format-wifi = "{icon}";
          format-disconnected = "󰤮 ";
          tooltip-format = "{ifname} via {gwaddr}";
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
          tooltip-format-ethernet = "{ifname}";
          tooltip-format-disconnected = "Disconnected";
          on-click = lib.getExe pkgs.rofi-network-manager;
        };
        "bluetooth" = {
          tooltip = true;
          format = "{icon}";
          format-on = "󰂯 ";
          format-off = "󰂲 ";
          format-connected = " ";
          tooltip-format = "{status}";
          tooltip-format-connected = "{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = lib.getExe pkgs.rofi-bluetooth;
          on-click-right = "pypr toggle bluetooth";
        };
        "tray" = {
          spacing = 5;
          show-passive-items = true;
        };
        "custom/exit" = {
          tooltip = false;
          format = " ";
          on-click = "sleep 0.1 && wlogout";
        };
        "custom/startmenu" = {
          tooltip = false;
          format = "";
          on-click = "sleep 0.1 && rofi -show drun -config ~/.config/rofi/icon.rasi";
        };
        "custom/pipewire" = {
          tooltip = false;
          max-length = 6;
          exec = pipewireStatus.outPath;
          on-click-right = "${pkgs.pwvucontrol}/bin/pwvucontrol";
        };
        "wireplumber" = {
          format = "{icon}";
          format-muted = " ";
          format-icons = ["" " " " "];
          on-click = "${pkgs.pw-volume}/bin/pw-volume mute toggle";
          on-click-right = "pypr toggle volume";
        };
        "custom/vpn" = {
          format = "{}";
          tooltip = true;
          tooltip-exec = "${pkgs.mullvad}/bin/mullvad status";
          exec = mullvadStatus.outPath;
          on-click = "${pkgs.mullvad}/bin/mullvad connect";
          on-click-right = "${pkgs.mullvad}/bin/mullvad disconnect";
          on-click-middle = "${pkgs.mullvad}/bin/mullvad reconnect";
        };
        "custom/screenshot" = let
          screenshot = flags: ''grim -g "$(slurp ${flags})" -t ppm - | satty -f -'';
          hyprshot = mode: "${pkgs.hyprshot}/bin/hyprshot -m ${mode} --freeze";
        in {
          format = " ";
          tooltip = true;
          on-click = hyprshot "region";
          on-click-right = screenshot "";
        };
        "idle_inhibitor" = {
          format = "{icon}";
          format-icons = {
            activated = " ";
            deactivated = "󰾫 ";
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
          format = "{icon}";
          format-charging = "󰂄";
          format-plugged = "󱘖";
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
          tooltip = true;
          tooltip-format = "{timeTo} ({capacity}%)";
        };
        "backlight" = {
          device = "intel_backlight";
          format = "{icon}";
          tooltip = false;
          format-icons = ["󰖙 " " " " " "󰖨 " " " " "];
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
      # {
      #   layer = "top";
      #   position = "left";
      #   modules-left = [
      #     "wlr/taskbar"
      #   ];
      # }
    ];
    style = with config.lib.stylix.colors; ''
      @define-color base00 #${base01};
      @define-color base01 #${base02};
      @define-color base02 #${base03};
      @define-color base03 #${base04};
      @define-color base04 #${base05};
      @define-color base05 #${base05};
      @define-color base06 #${base06};
      @define-color base07 #${base07};
      @define-color base08 #${base08};
      @define-color base09 #${base09};
      @define-color base0A #${base0A};
      @define-color base0B #${base0B};
      @define-color base0C #${base0C};
      @define-color base0D #${base0D};
      @define-color base0E #${base0E};
      @define-color base0F #${base0F};

      window#waybar {
        background-color: alpha(@base01, 0.3);
        border-bottom: 1px solid alpha(@base02, 0.5);
      }

      tooltip {
        background-color: alpha(@base01, 0.5);
      }

      box.horizontal box.modules-left > widget > *,
      box.horizontal box.modules-right > widget > * {
        color: @base05;
        background: @base01;
      }

      #workspaces {
        color: @base00;
        background: @base01;
      }

      #workspaces button {
        color: @base00;
        background: linear-gradient(45deg, @base0E, @base0F, @base0D, @base09);
      }

      #custom-startmenu {
        color: @base0D;
        background: @base01;
      }

      #custom-exit {
        color: @base00;
        background: linear-gradient(45deg, @base0C, @base0F, @base0B, @base08);
      }

      ${(builtins.unsafeDiscardStringContext (builtins.readFile ./style.css))}
    '';
  };
}
