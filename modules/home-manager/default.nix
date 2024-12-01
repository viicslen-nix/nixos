# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  # List your module files here
  default = ./imports.nix;

  autostart = import ./autostart;

  programs = {
    alacritty = import ./alacritty;
    lan-mouse = import ./lan-mouse;
    chromium = import ./chromium;
    kitty = import ./kitty;
    tinkerwell = import ./tinkerwell;
    ray = import ./ray;
    firefox = import ./firefox;
    zsh = import ./zsh;
    tmux = import ./tmux;
    aider = import ./aider;
    zellij = import ./zellij;
    corepack = import ./corepack;
  };
}
