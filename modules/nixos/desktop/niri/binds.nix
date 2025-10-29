{
  osConfig,
  config,
  lib,
  ...
}: let
  cfg = osConfig.modules.desktop.niri;
in {
  programs.niri.settings.binds = with lib;
  with config.lib.niri.actions; let
    sh = spawn "sh" "-c";

    # Determine which applications to use
    terminal =
      if cfg.terminal != null
      then getExe cfg.terminal
      else if (config.modules.functionality.defaults.terminal or null) != null
      then getExe config.modules.functionality.defaults.terminal
      else null;

    browser =
      if cfg.browser != null
      then getExe cfg.browser
      else if (config.modules.functionality.defaults.browser or null) != null
      then getExe config.modules.functionality.defaults.browser
      else null;

    editor =
      if cfg.editor != null
      then getExe cfg.editor
      else if (config.modules.functionality.defaults.editor or null) != null
      then getExe config.modules.functionality.defaults.editor
      else null;

    fileManager =
      if cfg.fileManager != null
      then getExe cfg.fileManager
      else if (config.modules.functionality.defaults.fileManager or null) != null
      then getExe config.modules.functionality.defaults.fileManager
      else null;

    passwordManager =
      if cfg.passwordManager != null
      then "${getExe cfg.passwordManager} --quick-access"
      else if (config.modules.functionality.defaults.passwordManager or null) != null
      then "${getExe config.modules.functionality.defaults.passwordManager} --quick-access"
      else null;

    # Application binds (only if apps are defined)
    appBinds =
      lib.optionalAttrs (terminal != null) {
        "Mod+Return".action = spawn terminal;
      }
      // lib.optionalAttrs (browser != null) {
        "Mod+B".action = spawn browser;
      }
      // lib.optionalAttrs (fileManager != null) {
        "Mod+E".action = spawn fileManager;
      }
      // lib.optionalAttrs (passwordManager != null) {
        "Ctrl+Shift+Space".action = sh passwordManager;
      };

    workspaceBinds = builtins.listToAttrs (builtins.concatLists (builtins.genList (
        x: let
          ws = let
            c = (x + 1) / 10;
          in
            builtins.toString (x + 1 - (c * 10));
          workspace = x + 1;
        in [
          {
            name = "Mod+${ws}";
            value.action.focus-workspace = workspace;
          }
          {
            name = "Mod+Shift+${ws}";
            value.action.move-column-to-workspace = workspace;
          }
        ]
      )
      10));
  in
    workspaceBinds
    // appBinds
    // {
      "Mod+O".action = show-hotkey-overlay;

      # window management
      "Mod+Q".action = close-window;
      "Mod+F".action = maximize-column;
      "Mod+T".action = toggle-window-floating;

      # focus movement
      "Mod+H".action = focus-column-left;
      "Mod+L".action = focus-column-right;
      "Mod+K".action = focus-window-up;
      "Mod+J".action = focus-window-down;

      # workspace cycling
      "Mod+Up".action = focus-workspace-up;
      "Mod+Down".action = focus-workspace-down;
      "Mod+Left".action = focus-column-left;
      "Mod+Right".action = focus-column-right;

      # monitor cycling
      "Mod+Shift+Left".action = focus-monitor-left;
      "Mod+Shift+Right".action = focus-monitor-right;
      "Mod+Shift+Up".action = focus-monitor-up;
      "Mod+Shift+Down".action = focus-monitor-down;

      # move workspace between monitors
      "Mod+Shift+Alt+Left".action = move-workspace-to-monitor-left;
      "Mod+Shift+Alt+Right".action = move-workspace-to-monitor-right;
      "Mod+Shift+Alt+Up".action = move-workspace-to-monitor-up;
      "Mod+Shift+Alt+Down".action = move-workspace-to-monitor-down;

      # dynamic cast
      "Mod+Insert".action = set-dynamic-cast-window;
      "Mod+Shift+Insert".action = set-dynamic-cast-monitor;
      "Mod+Delete".action = clear-dynamic-cast-target;

      # column tabbed display
      "Mod+Ctrl+Space".action = toggle-column-tabbed-display;

      # tab navigation
      "Mod+Tab".action = focus-window-down-or-column-right;
      "Mod+Shift+Tab".action = focus-window-up-or-column-left;

      # screenshots
      "Mod+Shift+S".action.screenshot = [];
      "Mod+Ctrl+S".action.screenshot-window = [];
      "Mod+Ctrl+Shift+S".action.screenshot-screen = [];

      # media controls
      "XF86AudioPlay".action = sh "playerctl play-pause";
      "XF86AudioPrev".action = sh "playerctl previous";
      "XF86AudioNext".action = sh "playerctl next";

      # launcher
      # "Mod+Space".action = spawn "fuzzel";

      # system
      # "Mod+Ctrl+L".action = spawn "blurred-locker";

      # volume controls
      # "XF86AudioRaiseVolume".action = sh "wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%+";
      # "XF86AudioLowerVolume".action = sh "wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%-";
      # "XF86AudioMute".action = sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      # "XF86AudioMicMute".action = sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

      # brightness controls
      # "XF86MonBrightnessUp".action = sh "brillo -q -u 300000 -A 5";
      # "XF86MonBrightnessDown".action = sh "brillo -q -u 300000 -U 5";

      # hotkey overlay
    };
}
