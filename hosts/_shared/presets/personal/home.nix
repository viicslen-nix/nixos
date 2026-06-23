{inputs, ...}: {
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
}
