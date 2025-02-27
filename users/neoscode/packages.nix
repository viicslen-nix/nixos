{ pkgs, ... }: with pkgs; [
  # Browsers
  brave
  microsoft-edge-wayland
  inputs.zen-browser.default

  # Remote
  remmina
  moonlight-qt

  # Communication
  discord
  dissent
  legcord

  # Development
  vial
  android-tools
  scrcpy
  openrgb-with-all-plugins
  jetbrains-toolbox
]
