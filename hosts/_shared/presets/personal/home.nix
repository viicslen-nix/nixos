{
  osConfig,
  inputs,
  lib,
  ...
}:
with lib; {
  imports = [
    inputs.hunk.homeManagerModules.default
    ./ai
  ];

  programs.hunk = {
    enable = true;
    enableGitIntegration = true;
    settings = {
      mode = "auto";
      wrap_lines = false;
      line_numbers = true;
      transparent_background = false;
    };
  };

  services.flameshot.enable = mkIf osConfig.modules.presets.desktop.enable true;
}
