# CONTEXT

The story behind the overlays in this directory. They are exported by
`parts/overlays.nix` and consumed by the base preset as `outputs.overlays.*`.

## The overlays

- **`flake-inputs`** — for every flake input, aliases `pkgs.inputs.${flake}` to
  `inputs.${flake}.packages.${pkgs.system}` or
  `inputs.${flake}.legacyPackages.${pkgs.system}`.
- **`additions`** — brings the custom packages from the `pkgs` directory in as
  `pkgs.local`.
- **`unstable-packages` / `stable-packages`** — make the unstable and stable
  nixpkgs sets (declared in the flake inputs) reachable as `pkgs.unstable` and
  `pkgs.stable`.
- **`modifications`** — whatever you want to overlay: changed versions,
  patches, compilation flags. See <https://nixos.wiki/wiki/Overlays>.

## `modifications.pythonPackagesExtensions`

dpcontracts' README doctest (pulled in via nix-alien → pylddwrap → icontract)
calls `asyncio.get_event_loop()`, which no longer implicitly creates a loop on
python 3.14, failing the build. The extension skips that check.
