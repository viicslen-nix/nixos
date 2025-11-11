{
  pkgs,
  lib,
  ...
}: let
  work = import ./work.nix {inherit pkgs;};
in {
  wayland.windowManager.hyprland = {
    settings.bind = [
      "$mod, d, submap, hyprflows"
    ];

    extraConfig = lib.mkAfter ''
      # apps
      submap = hyprflows

      binde = , 1, exec, ${lib.getExe work}

      bind = , escape, submap, reset
      bind = , catchall, submap, reset
      submap = reset
    '';
  };
}
