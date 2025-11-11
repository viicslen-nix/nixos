{
  pkgs,
  config,
  lib,
  ...
}: let
  webapp = name: url: (lib.concatStringsSep " " [
    "${lib.getExe pkgs.chromium}"
    "--user-data-dir=${config.xdg.configHome}/chromium/webapps/${name}"
    "--profile-directory=${name}"
    "--class=webapp-${name}"
    "--app=${url}"
  ]);
in {
  home.file.".config/hypr/pyprland.toml".text = ''
    [pyprland]
    plugins = [
      "monitors",
      "scratchpads",
      "toggle_special",
    ]

    [scratchpads.term]
    animation = "fromTop"
    command = "kitty --class kitty-dropterm"
    class = "kitty-dropterm"
    size = "75% 60%"

    [scratchpads.volume]
    animation = "fromRight"
    command = "pwvucontrol"
    class = "com.saivert.pwvucontrol"
    size = "40% 90%"
    unfocus = "hide"
    lazy = true

    [scratchpads.bluetooth]
    animation = "fromRight"
    command = "${lib.getExe pkgs.overskride}"
    class = "io.github.kaii_lb.Overskride"
    size = "40% 90%"
    unfocus = "hide"
    lazy = true

    [scratchpads.services]
    animation = "fromRight"
    command = "${pkgs.ferdium}/bin/ferdium"
    class = "ferdium"
    size = "60% 90%"
    unfocus = "hide"

    [scratchpads.notes]
    animation = "fromRight"
    command = "${lib.getExe pkgs.obsidian}"
    class = "obsidian"
    size = "40% 90%"
    unfocus = "hide"

    [scratchpads.messages]
    animation = "fromRight"
    command = "${(webapp "messages" "https://messages.google.com/web/u/2/conversations")}"
    class = "chrome-messages.google.com__web_u_2_conversations-messages"
    size = "40% 90%"
    unfocus = "hide"
    process_tracking = false

    [scratchpads.whatsapp]
    animation = "fromRight"
    command = "${(webapp "whatsapp" "https://web.whatsapp.com")}"
    class = "chrome-web.whatsapp.com__-whatsapp"
    size = "50% 90%"
    unfocus = "hide"
    process_tracking = false

    [scratchpads.gemini]
    animation = "fromRight"
    command = "${(webapp "gemini" "https://gemini.google.com")}"
    class = "brave-gemini.google.com__-gemini"
    size = "50% 90%"
    unfocus = "hide"
    process_tracking = false
  '';

  wayland.windowManager.hyprland = {
    settings = {
      exec-once = lib.mkAfter [
        "killall -q .pypr-wrapped; sleep .5 && pypr"
      ];
      bind = [
        "$mod, s, submap, scratchpads"
      ];
    };
    extraConfig = ''
      submap = scratchpads

      bind = , s, exec, pypr toggle services
      bind = , n, exec, pypr toggle notes
      bind = , m, exec, pypr toggle messages
      bind = , w, exec, pypr toggle whatsapp
      bind = , g, exec, pypr toggle gemini
      bind = , r, exec, killall -q pypr-wrapped; sleep .5 && pypr

      bind = , escape, submap, reset
      bind = , catchall, submap, reset
      submap = reset
    '';
  };
}
