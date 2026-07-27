{
  inputs,
  lib,
  osConfig,
  ...
}: {
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

  # GUI screenshot tool — only on graphical hosts.
  services.flameshot.enable = lib.mkIf osConfig.modules.presets.desktop.enable true;
}
