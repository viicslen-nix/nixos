# Custom packages and package modifications, exported as overlays.
# Consumed by the base preset as `outputs.overlays.*`.
{inputs, ...}: {
  flake.overlays = import ../overlays {inherit inputs;};
}
