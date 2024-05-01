{
  inputs,
  system,
  ...
}: let
  pkgs = import inputs.nixpkgs {
    inherit system;
  };
in
  pkgs.mkShell {
    packages = with pkgs; [
      zsh
      python3
      kubectl
      kubernetes-helm
      k9s
      popeye
      stern
      krr
    ];

    shellHook = ''
      exec zsh
    '';
  }
