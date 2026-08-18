# `pkgs` comes from parts/dev-shells.nix (vlib.pkgsFor, which sets
# allowUnfree) — forward it rather than letting each shell re-import nixpkgs,
# which silently dropped that config.
{pkgs, ...}: {
  kubernetes = import ./kubernetes.nix {inherit pkgs;};
  laravel = import ./laravel.nix {inherit pkgs;};
  python = import ./python.nix {inherit pkgs;};
}
