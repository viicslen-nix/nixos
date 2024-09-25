{
  home.file.".config/hyprland/pyprland.conf".text = ''
    [pyprland]
    plugins = [
      "scratchpads",
      "toggle_special",
    ]

    # [scratchpads.term]
    # command = "kitty --class kitty_dropdown"
    # animation = "fromTop"
    # unfocus = "hide"
    # excludes = "*"
    # lazy = true
    # multi = false

    # [scratchpads.volume]
    # command = "pavucontrol --class volume_sidemenu"
    # animation = "fromLeft"
    # class = "volume_sidemenu"
    # size = "40% 70%"
    # unfocus = "hide"
    # excludes = "*"
    # lazy = true
    # margin = 90
    # multi = false


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
  '';
}