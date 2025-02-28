{pkgs, ...}: {
  wayland.windowManager.hyprland = {
    plugins = [
      pkgs.inputs.hyprchroma.Hypr-DarkWindow
    ];

    settings.windowrulev2 = [
      "plugin:chromakey, title:(.*)(Visual Studio Code)$"
      "plugin:chromakey, class:^(.*jetbrains.*)$"
      "plugin:chromakey, class:^(discord)$"
      "plugin:chromakey, class:^(legcord)$"
    ];
  };
}
