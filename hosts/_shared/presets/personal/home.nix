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

      # Defaults are already vim-ish (j/k, g/G, d/u, [/]); this fills the gaps.
      # Binding a key takes it from whatever held it as a default, so
      # toggleLineNumbers needs a new home once `l` scrolls right.
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

  # Not `llm-agents.t3code-desktop` — that is a symlinkJoin of the *stock*
  # `t3code.desktop`, so it never sees the module's T3 Connect patch. The
  # module installs the desktop output of this same package instead.
  modules.programs.t3code.package = pkgs.inputs.llm-agents.t3code;
}
