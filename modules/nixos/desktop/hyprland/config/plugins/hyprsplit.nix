{pkgs, ...}: let
  # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
  workspaces = builtins.concatLists (builtins.genList (
      x: let
        ws = let
          c = (x + 1) / 10;
        in
          builtins.toString (x + 1 - (c * 10));
      in [
        "$mod, ${ws}, split:workspace, ${toString (x + 1)}"
        "$mod SHIFT, ${ws}, split:movetoworkspacesilent, ${toString (x + 1)}"
      ]
    )
    10);
in {
  wayland.windowManager.hyprland = {
    plugins = [
      pkgs.inputs.hyprsplit.hyprsplit
      # pkgs.hyprlandPlugins.hyprsplit
    ];

    settings = {
      plugin.hyprsplit = {
        num_workspaces = 10;
        persistent_workspaces = false;
      };

      bind =
        [
          "$mod, G, split:grabroguewindows"
        ]
        ++ workspaces;
    };
  };
}
