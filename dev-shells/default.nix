{
  inputs,
  system,
  config,
  pkgs,
  ...
}: {
  default = pkgs.mkShell {
    inputsFrom = [ config.mission-control.devShell ];
  };
  kubernetes = import ./kubernetes.nix {inherit inputs system;};
  laravel = import ./laravel.nix {inherit inputs system;};
  python = import ./python.nix {inherit inputs system;};
}
