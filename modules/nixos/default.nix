# Add your reusable NixOS modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  all = import ./all.nix;

  # Containers
  containers = import ./containers;

  # Presets
  presets = {
    base = import ./presets/base;
    work = import ./presets/work;
    linode = import ./presets/linode;
    personal = import ./presets/personal;
  };

  # Hardware
  hardware = {
    asus = import ./hardware/asus;
    intel = import ./hardware/intel;
    nvidia = import ./hardware/nvidia;
    display = import ./hardware/display;
    bluetooth = import ./hardware/bluetooth;
  };

  # Desktop
  desktop = {
    kde = import ./desktop/kde;
    gnome = import ./desktop/gnome;
  };

  # Functionality
  functionality = {
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
  };

  # Programs
  programs = {
    ld = import ./programs/ld;
    qmk = import ./programs/qmk;
    docker = import ./programs/docker;
    steam = import ./programs/steam;
    mkcert = import ./programs/mkcert;
    podman = import ./programs/podman;
    kanata = import ./programs/kanata;
    mullvad = import ./programs/mullvad;
    corepack = import ./programs/corepack;
    one-password = import ./programs/one-password;
    github-runner = import ./programs/github-runner;
  };
}
