{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  user,
  ...
}: {
  home.packages = with pkgs; [
    microsoft-edge-wayland
    termius
    appflowy
  ];

  features.lan-mouse.enable = true;
  features.lan-mouse.autostart = true;

  programs.ray.enable = true;
  programs.tinkerwell.enable = true;
}
