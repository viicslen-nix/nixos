{
  pkgs,
  config,
  ...
}: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    extraConfig = {
      modi = "drun,filebrowser,run";
      terminal = "${pkgs.kitty}/bin/kitty";
      location = 0;
      show-icons = true;
      drun-display-format = "{icon} {name}";
      display-drun = "  Apps";
      display-run = "  Run";
      display-filebrowser = "  File";
    };
    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
      wallpaper = config.stylix.image;
    in {
      "*" = {
        bg = mkLiteral "#${config.lib.stylix.colors.base00}";
        bg-alt = mkLiteral "#${config.lib.stylix.colors.base09}";
        selected = mkLiteral "#${config.lib.stylix.colors.base08}";
        text-selected = mkLiteral "#${config.lib.stylix.colors.base00}";
      };
      "window" = {
        width = mkLiteral "50%";
        transparency = "real";
        orientation = mkLiteral "vertical";
        cursor = mkLiteral "default";
        spacing = mkLiteral "0px";
        border = mkLiteral "2px";
        border-color = "@border-color";
        border-radius = mkLiteral "20px";
      };
      "mainbox" = {
        padding = mkLiteral "15px";
        enabled = true;
        orientation = mkLiteral "horizontal";
        children = map mkLiteral [
          "inputbar"
          "listbox"
        ];
        background-color = mkLiteral "transparent";
      };
      "inputbar" = {
        enabled = true;
        width = mkLiteral "20%";
        padding = mkLiteral "10px";
        margin = mkLiteral "10px";
        background-color = mkLiteral "transparent";
        border-radius = "25px";
        orientation = mkLiteral "vertical";
        children = map mkLiteral [
          "entry"
          "dummy"
          "mode-switcher"
        ];
        background-image = mkLiteral ''url("${wallpaper}", height)'';
      };
      "entry" = {
        enabled = true;
        expand = false;
        width = mkLiteral "20%";
        padding = mkLiteral "10px";
        border-radius = mkLiteral "12px";
        background-color = mkLiteral "@selected";
        cursor = mkLiteral "text";
        placeholder = "🖥️ Search ";
        placeholder-color = mkLiteral "inherit";
      };
      "listbox" = {
        spacing = mkLiteral "10px";
        padding = mkLiteral "10px";
        background-color = mkLiteral "transparent";
        orientation = mkLiteral "vertical";
        children = map mkLiteral [
          "message"
          "listview"
        ];
      };
      "listview" = {
        enabled = true;
        columns = 1;
        lines = 8;
        cycle = true;
        dynamic = true;
        scrollbar = false;
        layout = mkLiteral "vertical";
        reverse = false;
        fixed-height = false;
        fixed-columns = true;
        spacing = mkLiteral "10px";
        background-color = mkLiteral "transparent";
        border = mkLiteral "0px";
      };
      "dummy" = {
        expand = true;
        background-color = mkLiteral "transparent";
      };
      "mode-switcher" = {
        enabled = true;
        spacing = mkLiteral "10px";
        background-color = mkLiteral "transparent";
      };
      "button" = {
        width = mkLiteral "5%";
        padding = mkLiteral "12px";
        border-radius = mkLiteral "12px";
        background-color = mkLiteral "@text-selected";
        cursor = mkLiteral "pointer";
      };
      "scrollbar" = {
        width = mkLiteral "4px";
        border = 0;
        handle-width = mkLiteral "8px";
        padding = 0;
      };
      "element" = {
        enabled = true;
        spacing = mkLiteral "10px";
        padding = mkLiteral "10px";
        border-radius = mkLiteral "12px";
        background-color = mkLiteral "transparent";
        cursor = mkLiteral "pointer";
        children = map mkLiteral [
          "element-text"
        ];
      };
      "element-icon" = {
        size = mkLiteral "36px";
        cursor = mkLiteral "inherit";
      };
      "element-text" = {
        font = "JetBrainsMono Nerd Font Mono 12";
        cursor = mkLiteral "inherit";
        vertical-align = mkLiteral "0.5";
        horizontal-align = mkLiteral "0.0";
      };
      "message" = {
        background-color = mkLiteral "transparent";
        border = mkLiteral "0px";
      };
      "textbox" = {
        padding = mkLiteral "12px";
        border-radius = mkLiteral "10px";
        background-color = mkLiteral "@bg-alt";
        vertical-align = mkLiteral "0.5";
        horizontal-align = mkLiteral "0.0";
      };
      "error-message" = {
        padding = mkLiteral "12px";
        border-radius = mkLiteral "20px";
        background-color = mkLiteral "@bg-alt";
        text-color = mkLiteral "@bg";
      };
    };
  };

  wayland.windowManager.hyprland.settings = let
    rofi = pkgs.writeShellScriptBin "launcher" ''
      if pgrep -x "rofi" > /dev/null; then
        # Rofi is running, kill it
        pkill -x rofi
        exit 0
      fi
      ${pkgs.rofi-wayland}/bin/rofi -show drun
    '';
    launcher = "${rofi}/bin/launcher";
    emojiPicker = import ./scripts/emoji-picker.nix {inherit pkgs;};
    webSearch = import ./scripts/web-search.nix {inherit pkgs;};
  in {
    bindr = [
      "$mod, Space, exec, ${launcher} -show drun -config ~/.config/rofi/icon.rasi"
    ];

    bind = [
      "$mod, v, exec, cliphist list | ${launcher} -dmenu -config ~/.config/rofi/long.rasi | cliphist decode | wl-copy"
      "$mod, o, exec, ${emojiPicker}/bin/emoji-picker"
      "$mod, w, exec, ${webSearch}/bin/web-search -config ~/.config/rofi/long.rasi"
    ];

    # windowrule = [
    #   "noborder, rofi"
    #   "center, rofi"
    # ];

    layerrule = [
      "blur,^(rofi)$"
    ];
  };

  home.file = {
    ".config/rofi/emoji.rasi".source = ./emoji.rasi;
    ".config/rofi/icon.rasi".source = ./icon.rasi;
  };
}
