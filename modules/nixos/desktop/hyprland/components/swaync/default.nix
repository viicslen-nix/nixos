{lib, config, ...}: with lib; {
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

    style = with config.lib.stylix.colors;''
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

      ${(builtins.unsafeDiscardStringContext (builtins.readFile ./style.css))}
    '';
  };
}
