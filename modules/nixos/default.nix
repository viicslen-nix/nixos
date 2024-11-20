# Add your reusable NixOS modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  # List your module files here
  # my-module = import ./my-module.nix;
  imports = ./imports.nix;

  # Presets
  base = import ./presets/base;
  work = import ./presets/work;
  linode = import ./presets/linode;
  personal = import ./presets/personal;

  # Hardware
  asus = import ./hardware/asus;
  intel = import ./hardware/intel;
  nvidia = import ./hardware/nvidia;
  display = import ./hardware/display;

  # Desktop
  kde = import ./desktop/kde;
  gnome = import ./desktop/gnome;
  hyprland = import ./desktop/hyprland;

  # Functionality
  oom = import ./functionality/oom;
  sound = import ./functionality/sound;
  theming = import ./functionality/theming;
  network = import ./functionality/network;
  backups = import ./functionality/backups;
  app-images = import ./functionality/app-images;
  localization = import ./functionality/localization;
  impermanence = import ./functionality/impermanence;
  power-management = import ./functionality/power-management;
  virtual-machines = import ./functionality/virtual-machines;

  # Programs
  qmk = import ./programs/qmk;
  docker = import ./programs/docker;
  mkcert = import ./programs/mkcert;
  podman = import ./programs/podman;
  mullvad = import ./programs/mullvad;
  corepack = import ./programs/corepack;
  one-password = import ./programs/one-password;
  github-runner = import ./programs/github-runner;

  # Containers
  containers = import ./containers;
}
