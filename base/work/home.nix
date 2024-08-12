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

  programs.ray.enable = true;
  programs.tinkerwell.enable = true;
}
