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
    command = "pavucontrol"
    class = "org.pulseaudio.pavucontrol"
    lazy = true
    size = "40% 90%"
    unfocus = "hide"

    [monitors.placement."G276HL"]
    topOf = "eDP-1"
  '';
}
