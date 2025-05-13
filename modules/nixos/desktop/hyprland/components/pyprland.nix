{pkgs, lib, ...}: {
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
    lazy = true
    size = "40% 90%"
    unfocus = "hide"

    [scratchpads.bluetooth]
    animation = "fromRight"
    command = "blueman-manager"
    class = ".blueman-manager-wrapped"
    lazy = true
    size = "40% 90%"
    unfocus = "hide"

    [scratchpads.messages]
    animation = "fromRight"
    command = "${lib.getExe pkgs.chromium} --app=https://messages.google.com/web/u/2/conversations"
    class = "chrome-messages.google.com__web_u_2_conversations-Default"
    lazy = true
    size = "40% 90%"
    unfocus = "hide"

    [scratchpads.whatsapp]
    animation = "fromRight"
    command = "${lib.getExe pkgs.chromium} --app=https://web.whatsapp.com/"
    class = "chrome-web.whatsapp.com__-Default"
    lazy = true
    size = "50% 90%"
    unfocus = "hide"

    [scratchpads.gemini]
    animation = "fromRight"
    command = "${lib.getExe pkgs.chromium} --app=https://gemini.google.com/"
    class = "chrome-gemini.google.com__-Default"
    lazy = true
    size = "50% 90%"
    unfocus = "hide"
  '';

  wayland.windowManager.hyprland = {
    settings.bind = [
      "$mod, s, submap, scratchpads"
    ];
    extraConfig = ''
      submap = scratchpads

      binde = , m, exec, pypr toggle messages
      binde = , w, exec, pypr toggle whatsapp
      binde = , g, exec, pypr toggle gemini

      bind = , escape, submap, reset
      bind = , catchall, submap, reset
      submap = reset
    '';
  };
}
