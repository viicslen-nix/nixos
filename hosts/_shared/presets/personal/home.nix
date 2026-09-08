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

      # Binding a key steals it from its default holder — rehome, don't drop.
      keybindings = {
        "hunk.review.scrollCodeLeft" = ["h" "left" "shift+left"];
        "hunk.review.scrollCodeRight" = ["l" "right" "shift+right"];
        "hunk.view.toggleLineNumbers" = "ctrl+l";
        "hunk.review.pageDown" = ["ctrl+f" "pagedown" "space"];
        "hunk.review.pageUp" = ["ctrl+b" "pageup" "shift+space"];
      };
    };
  };

  services.flameshot.enable = mkIf osConfig.modules.presets.desktop.enable true;

  # Not `llm-agents.t3code-desktop` — it misses the module's T3 Connect patch.
  modules.programs.t3code.package = pkgs.inputs.llm-agents.t3code;
}
