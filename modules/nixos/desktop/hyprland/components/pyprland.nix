{
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
  '';
}
