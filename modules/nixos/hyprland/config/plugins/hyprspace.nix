{pkgs, ...}: {
  wayland.windowManager.hyprland = {
    plugins = [
      pkgs.inputs.hyprspace.Hyprspace
    ];

    settings = {
      plugin.overview = {
        centerAligned = true;
        hideTopLayers = true;
        hideOverlayLayers = true;
        showNewWorkspace = true;
        exitOnClick = true;
        exitOnSwitch = true;
        drawActiveWorkspace = true;
        reverseSwipe = true;
      };

      bind = [
        "$mod, Tab, overview:toggle"
      ];
    };
  };
}
