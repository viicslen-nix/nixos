{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; {
  config = {
    environment.systemPackages = with pkgs; [
      nix-alien
      nix-init
      graphviz
      asciinema
      yazi
      inputs.nixvim.default
      local.scripts.git-carve-submodule
      ytmdesktop
      android-tools
    ];

    programs = {
      localsend.enable = mkDefault true;
    };

    modules.programs.qmk.enable = mkDefault true;
    modules.containers.homarr.enable = mkDefault true;
  };
}
