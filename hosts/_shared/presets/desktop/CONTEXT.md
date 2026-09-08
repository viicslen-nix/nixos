# CONTEXT

The `desktop` preset — all graphical/physical-machine config. This file holds
the reasoning behind `default.nix`.

## The nixpkgs-wayland overlay is desktop-scoped

`inputs.nixpkgs-wayland.overlay` supplies bleeding-edge Wayland packages
(waybar, swww, portals, utils, …). It is added here rather than in `base` so it
only reaches graphical desktop hosts: headless/WSL hosts don't need it and
would otherwise recompile the overlaid closure from source on every update.

## Binary caches for that overlay

The caches that let the overlay and the ghostty flake substitute instead of
building from source are declared in `caches.nix` at the repo root with
`scope = "desktop"`. That scope is what keeps them off headless/WSL hosts, so a
cache is added there and never inline here.
