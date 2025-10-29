{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "personal";
  namespace = "presets";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nix-alien
      nix-init
      graphviz
      asciinema
      yazi
      inputs.neovim.default
    ];

    programs = {
      adb.enable = mkDefault true;
      localsend.enable = mkDefault true;
    };

    modules.programs.qmk.enable = mkDefault true;
  };
}
