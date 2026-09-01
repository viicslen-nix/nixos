{
  lib,
  pkgs,
  osConfig,
  homeModules,
  ...
}: let
  # Login layout: vivaldi on Browser (DP-1); legcord + ghostty stacked 50/50 in
  # one column on Communication (DP-2). The window-rules below place vivaldi and
  # legcord — a rule can pin a window to a workspace but cannot drop it into an
  # existing column, so only the ghostty half needs a script.
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
  ];

  home.file.".config/hypr/pyprland.toml".text = lib.mkAfter ''
    [monitors.placement."LW9AA0048525"]
    rightOf = "DP-1"
    transform = 1
  '';

  home.autostart = [
    {
      package = pkgs.jetbrains-toolbox;
      delay = 5;
    }
  ];

  wayland.windowManager.hyprland.settings = lib.mkIf osConfig.programs.hyprland.enable {
    monitor = [
      "DP-1, 1920x1080@59.99, 0x0, 1, vrr, 0"
      "DP-2, 1920x1080@59.99, 1920x0, 1, transform, 3, vrr, 0"
      ", preferred, auto, 1"
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
