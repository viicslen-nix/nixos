{pkgs, ...}:
with pkgs; [
  # Browsers
  microsoft-edge-wayland
  inputs.zen-browser.default

  # Communication
  legcord

  # Development
  vial
  android-tools
  scrcpy
  openrgb-with-all-plugins
  jetbrains-toolbox
]
