{pkgs, ...}: {
  wayland.windowManager.hyprland = {
    plugins = [
      pkgs.inputs.hyprsplit.hyprsplit
    ];

    settings.plugin.hyprsplit = {
      num_workspaces = 10;
      persistent_workspaces = false;
    };
  };
}
