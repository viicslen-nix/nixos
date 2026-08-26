{
  lib,
  pkgs,
  inputs,
  osConfig,
  homeModules,
  ...
}:
with lib; {
  imports = [
    inputs.hunk.homeManagerModules.default
    homeModules.programs.ai
    homeModules.programs.claude-code
    homeModules.programs.t3code
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

  # Not `llm-agents.t3code-desktop` — that is a symlinkJoin of the *stock*
  # `t3code.desktop`, so it never sees the module's T3 Connect patch. The
  # module installs the desktop output of this same package instead.
  modules.programs.t3code.package = pkgs.inputs.llm-agents.t3code;
}
