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

    [monitors.placement."G276HL"]
    topOf = "eDP-1"

    [monitors.placement."G274F"]
    leftOf = "eDP-1"

    [monitors.placement."Acer CB281HK"]
    topOf = "DP-1"
    scale = 1.875000
  '';
}
