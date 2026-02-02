{
  lib,
  pkgs,
  config,
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
      ytmdesktop
      android-tools
      inputs.nixvim.default
      local.scripts.git-carve-submodule
    ];

    programs = {
      localsend.enable = mkDefault true;
    };

    modules = {
      core.theming.enable = true;
      programs.qmk.enable = mkDefault true;
      containers.homarr.enable = mkDefault true;
    };
  };
}
