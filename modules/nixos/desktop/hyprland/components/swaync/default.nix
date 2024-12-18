{
  lib,
  config,
  ...
}:
with lib; {
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "killall -q swaync;sleep .5 && swaync"
    ];

    bind = [
      "$mod SHIFT, N, exec, swaync-client -op"
    ];

    layerrule = [
      "blur, ^(swaync-control-center)$"
      "blurpopups, ^(swaync-control-center)$"
      "ignorealpha 0.2, ^(swaync-control-center)$"
    ];
  };

  stylix.targets.swaync.enable = false;

  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";
      control-center-margin-top = 10;
      control-center-margin-bottom = 10;
      control-center-margin-right = 10;
      control-center-margin-left = 10;
      notification-icon-size = 64;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      timeout = 10;
      timeout-low = 5;
      timeout-critical = 0;
      fit-to-screen = true;
      control-center-width = 500;
      notification-window-width = 500;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = true;
      widgets = [
        "title"
        "mpris"
        "volume"
        "backlight"
        "dnd"
        "notifications"
      ];
      widget-config = {
        title = {
          text = "Notification Center";
          clear-all-button = true;
          button-text = "󰆴 Clear All";
        };
        dnd = {
          text = "Do Not Disturb";
        };
        label = {
          max-lines = 1;
          text = "Notification Center";
        };
        mpris = {
          image-size = 96;
          image-radius = 7;
        };
        volume = {
          label = "󰕾";
        };
        backlight = {
          label = "󰃟";
        };
      };
    };

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

      .control-center .notification-row:focus,
      .control-center .notification-row:hover {
        background: #${config.stylix.base16Scheme.base00}
      }
      .notification-content {
        background: #${config.stylix.base16Scheme.base00};
        border: 2px solid #${config.stylix.base16Scheme.base0D};
      }
      .close-button {
        background: #${config.stylix.base16Scheme.base08};
        color: #${config.stylix.base16Scheme.base00};
      }
      .close-button:hover {
        background: #${config.stylix.base16Scheme.base0D};
      }
      .notification-action {
        border: 2px solid #${config.stylix.base16Scheme.base0D};
      }
      .notification-default-action:hover,
      .notification-action:hover {
        color: #${config.stylix.base16Scheme.base0B};
        background: #${config.stylix.base16Scheme.base0B}
      }
      .notification-action:first-child {
        background: #${config.stylix.base16Scheme.base00}
      }
      .notification-action:last-child {
        background: #${config.stylix.base16Scheme.base00}
      }
      .inline-reply-entry {
        background: #${config.stylix.base16Scheme.base00};
        color: #${config.stylix.base16Scheme.base05};
        caret-color: #${config.stylix.base16Scheme.base05};
        border: 1px solid #${config.stylix.base16Scheme.base09};
      }
      .inline-reply-button {
        background: #${config.stylix.base16Scheme.base00};
        border: 1px solid #${config.stylix.base16Scheme.base09};
        color: #${config.stylix.base16Scheme.base05}
      }
      .inline-reply-button:disabled {
        color: #${config.stylix.base16Scheme.base03};
      }
      .inline-reply-button:hover {
        background: #${config.stylix.base16Scheme.base00}
      }
      .body-image {
        background-color: #${config.stylix.base16Scheme.base05};
      }
      .time {
        color: #${config.stylix.base16Scheme.base05};
      }
      .body {
        color: #${config.stylix.base16Scheme.base05};
      }
      .control-center {
        background: #${config.stylix.base16Scheme.base00};
        border: 2px solid #${config.stylix.base16Scheme.base0C};
      }
      .widget-title {
        color: #${config.stylix.base16Scheme.base0B};
        background: #${config.stylix.base16Scheme.base00};
      }
      .widget-title>button {
        color: #${config.stylix.base16Scheme.base05};
        background: #${config.stylix.base16Scheme.base00};
      }
      .widget-title>button:hover {
        background: #${config.stylix.base16Scheme.base08};
        color: #${config.stylix.base16Scheme.base00};
      }
      .widget-dnd {
        background: #${config.stylix.base16Scheme.base00};
        color: #${config.stylix.base16Scheme.base0B};
      }
      .widget-dnd>switch {
        background: #${config.stylix.base16Scheme.base0B};
      }
      .widget-dnd>switch:checked {
        background: #${config.stylix.base16Scheme.base08};
        border: 1px solid #${config.stylix.base16Scheme.base08};
      }
      .widget-dnd>switch slider {
        background: #${config.stylix.base16Scheme.base00};
      }
      .widget-dnd>switch:checked slider {
        background: #${config.stylix.base16Scheme.base00};
      }
      .widget-label>label {
        color: #${config.stylix.base16Scheme.base05};
      }
      .widget-mpris {
        color: #${config.stylix.base16Scheme.base05};
      }
      .widget-volume {
        background: #${config.stylix.base16Scheme.base01};
        color: #${config.stylix.base16Scheme.base05};
      }
      .widget-volume>box>button {
        background: #${config.stylix.base16Scheme.base0B};
      }
      .per-app-volume {
        background-color: #${config.stylix.base16Scheme.base00};
      }
      .widget-backlight {
        background: #${config.stylix.base16Scheme.base01};
        color: #${config.stylix.base16Scheme.base05}
      }


      ${(builtins.unsafeDiscardStringContext (builtins.readFile ./style.css))}
    '';
  };
}
