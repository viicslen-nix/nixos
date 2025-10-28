{
  lib,
  pkgs,
  ...
}: {
  # home.packages = with pkgs; [
  #   legcord
  # ];

  modules = {
    programs = {
      kitty.enable = true;
    };
  };

  wayland.windowManager.hyprland.settings = {
    cursor = {
      no_hardware_cursors = 1;
      use_cpu_buffer = 0;
    };
  };
}
