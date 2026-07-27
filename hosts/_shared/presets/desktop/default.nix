{inputs, ...}: {
  # Bleeding-edge Wayland packages (waybar, swww, portals, utils, ...).
  # Scoped to graphical desktop hosts — headless/WSL hosts don't need it and
  # would otherwise recompile the overlaid closure from source on every update.
  nixpkgs.overlays = [inputs.nixpkgs-wayland.overlay];

  # Binary caches so the overlay and the ghostty flake substitute instead of
  # building from source.
  nix.settings = {
    substituters = [
      "https://nixpkgs-wayland.cachix.org"
      "https://ghostty.cachix.org"
    ];
    trusted-public-keys = [
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
    ];
  };
}
