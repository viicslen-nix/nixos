{
  inputs,
  pkgs,
  ...
}: {
  myVimPlugins = import ./vim-plugins {inherit pkgs;};
  myScripts = import ./scripts {inherit pkgs;};
  iso-image = import ./iso {inherit inputs pkgs;};
  myhelm-secrets = pkgs.callPackage ./helm-plugins/secrets.nix {};
}
