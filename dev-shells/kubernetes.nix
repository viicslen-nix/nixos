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
      kubernetes-helmPlugins.helm-secrets
      k9s
      popeye
      stern
      minikube
      vals
    ];

    shellHook = ''
      export HELM_SECRETS_BACKEND=vals
      export HELM_SECRETS_VALS_PATH="${pkgs.vals}/bin/vals"
      exec zsh
    '';
  }
