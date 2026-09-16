{
  lib,
  pkgs,
  osConfig,
  homeModules,
  ...
}: let
  # A window rule cannot drop a window into an existing column — hence this script.
  loginLayout = pkgs.writeShellScript "niri-login-layout" ''
    set -u
    PATH=${lib.makeBinPath [pkgs.jq pkgs.coreutils]}:$PATH

    # ponytail: polls instead of reading niri's event stream. Login is the only
    # caller and no ghostty is running yet, so the first match is our window.
    await() {
      for _ in $(seq 100); do
        id=$(niri msg --json windows |
          jq -r --arg a "$1" 'map(select(.app_id == $a)) | .[0].id // empty')
        [ -n "$id" ] && { echo "$id"; return 0; }
        sleep 0.2
      done
      return 1
    }

    vivaldi &
    legcord &
    await legcord >/dev/null || exit 0

    ghostty &
    gid=$(await com.mitchellh.ghostty) || exit 0
    niri msg action move-window-to-workspace --window-id "$gid" --focus false Communication
    niri msg action consume-or-expel-window-left --id "$gid"
    niri msg action set-window-height --id "$gid" 50%
  '';
in {
  imports = with homeModules; [
    programs.ray
    programs.kitty
    programs.tinkerwell
    programs.zen-browser
    programs.webapps
    programs.thunderbird
  ];

  home.autostart = [
    {
      package = pkgs.jetbrains-toolbox;
      delay = 5;
    }
  ];

  wayland.windowManager.hyprland.settings = lib.mkIf osConfig.programs.hyprland.enable {
    monitor = [
      {
        output = "DP-1";
        mode = "1920x1080@59.99";
        position = "0x0";
        scale = 1;
        vrr = 0;
      }
      {
        output = "DP-2";
        mode = "1920x1080@59.99";
        position = "1920x0";
        scale = 1;
        transform = 1;
        vrr = 0;
      }
    ];
  };

  programs = {
    niri.settings = lib.mkIf osConfig.programs.niri.enable {
      workspaces = {
        "browser" = {
          name = "Browser";
          open-on-output = "DP-1";
        };
        "editor" = {
          name = "Editor";
          open-on-output = "DP-1";
        };
        "communication" = {
          name = "Communication";
          open-on-output = "DP-2";
        };
        "system" = {
          name = "System";
          open-on-output = "DP-2";
        };
      };

      window-rules = [
        {
          matches = [{app-id = "^vivaldi";}];
          open-on-workspace = "Browser";
        }
        {
          matches = [{app-id = "^legcord$";}];
          open-on-workspace = "Communication";
        }
        {
          # Pinned only — nothing launches these at login.
          matches = [
            {app-id = "^jetbrains-phpstorm$";}
            {app-id = "^t3code$";}
            {app-id = "(?i)^superset$";}
          ];
          open-on-workspace = "Editor";
        }
      ];

      spawn-at-startup = [{sh = "${loginLayout}";}];

      binds = {
        "Mod+F1".action.spawn = ["zen-browser"];
        "Mod+F2".action.spawn = ["phpstorm"];
        "Mod+F3".action.spawn = ["legcode" "--split=top" "kitty" "--split=bottom"];
        "Mod+F4".action.spawn = ["code" "--split=top" "kitty" "--split=bottom"];
      };
    };

    dank-material-shell.niri.includes.filesToInclude = [
      "custom"
    ];

    opencode.settings.provider.ollama = {
      name = "Ollama";
      npm = "@ai-sdk/openai-compatible";
      models."qwen3.5".name = "Qwen 3.5";
      options.baseUrl = "http://localhost:11434/v1";
    };
  };

  services = {
    tailscale-systray = {
      enable = true;
      theme = "dark:nobg";
    };
    trayscale.enable = true;
  };
}
