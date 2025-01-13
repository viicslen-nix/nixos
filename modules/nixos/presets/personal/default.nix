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
    # Enable Plymouth
    boot.plymouth.enable = true;

    environment.systemPackages = with pkgs; [
      insomnia
      nix-alien
      nix-init
      lens
      skypeforlinux
      kdePackages.kcachegrind
      graphviz
      sesh
      asciinema
      waveterm
      yazi

      # GUI Apps
      tangram
      endeavour
      drawing
      kooha

      # Development
      vscode
      obsidian
      drawio
    ];

    programs.adb.enable = true;

    modules.programs = {
      qmk.enable = true;
      mullvad.enable = true;

      onePassword = {
        enable = true;
        gitSignCommits = true;
        allowedCustomBrowsers = [".zen-wrapped"];
      };

      steam.enable = true;
    };
  };
}
