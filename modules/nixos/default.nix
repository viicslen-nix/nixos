# Add your reusable NixOS modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  # List your module files here
  # my-module = import ./my-module.nix;
  kde = import ./kde;
  gnome = import ./gnome;
  sound = import ./sound;
  docker = import ./docker;
  podman = import ./podman;
  theming = import ./theming;
  network = import ./network;
  mullvad = import ./mullvad;
  hyprland = import ./hyprland;
  app-images = import ./app-images;
  localization = import ./localization;
  one-password = import ./one-password;
  virtual-machines = import ./virtual-machines;
}
