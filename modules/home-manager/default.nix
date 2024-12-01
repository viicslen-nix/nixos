# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  # List your module files here
  default = ./imports.nix;
  defaults = ./defaults;

  functionality = {
    autostart = import ./functionality/autostart;
    impermanence = import ./functionality/impermanence;
  };

  programs = {
    nushell = import ./programs/nushell;
    starship = import ./programs/starship;
    alacritty = import ./programs/alacritty;
    lan-mouse = import ./programs/lan-mouse;
    chromium = import ./programs/chromium;
    kitty = import ./programs/kitty;
    tinkerwell = import ./programs/tinkerwell;
    ray = import ./programs/ray;
    firefox = import ./programs/firefox;
    zsh = import ./programs/zsh;
    tmux = import ./programs/tmux;
    aider = import ./programs/aider;
    zellij = import ./programs/zellij;
    corepack = import ./programs/corepack;
  };
}
