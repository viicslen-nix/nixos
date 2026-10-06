{
  lib,
  pkgs,
  config,
  inputs,
  osConfig,
  homeModules,
  ...
}:
with lib; {
  imports = [
    inputs.hunk.homeManagerModules.default
    inputs.ai.homeManagerModules.ai
    inputs.ai.homeManagerModules.claude-code
    inputs.ai.homeManagerModules.profile
    homeModules.programs.t3code
  ];

  age.secrets = {
    avante-anthropic-api-key.file = ../../secrets/avante/anthropic-api-key.age;
    stitch-api-key.file = ../../secrets/stitch/api-key.age;
    cliproxyapi-api-key.file = ../../secrets/cliproxyapi/api-key.age;
  };

  # Not the gateway's `env_files` — it can't expand the path, sending an empty header.
  systemd.user.services.mcp-gateway.Service.EnvironmentFile = "%t/agenix/stitch-api-key";

  modules.programs.ai = {
    integrations.browser-harness = {
      enable = true;
      headless.enable = true;
    };
    # Stays here, not in the ai flake: it needs a credential only this host has.
    # Not `oauth.enabled` — accounts.google.com has no registration_endpoint.
    mcps.google_stitch = {
      url = "https://stitch.googleapis.com/mcp";
      headers."X-Goog-Api-Key" = "\${STITCH_API_KEY}";
    };
    proxy = {
      baseUrl = "https://cliproxyapi.tailb6b9b6.ts.net";
      apiKeyFile = config.age.secrets.cliproxyapi-api-key.path;
      models = let
        thinking = api: {
          inherit api;
          reasoning = true;
        };
      in {
        claude-opus-5-5 = thinking "anthropic";
        claude-sonnet-5-5 = thinking "anthropic";
        claude-haiku-4-5-20251001 = thinking "anthropic";
        claude-fable-5-1 = thinking "anthropic";
        "gpt-6.1-sol" = thinking "openai";
        gpt-6-sol = thinking "openai";
        gpt-6-luna = thinking "openai";
        "gpt-5.6-sol" = thinking "openai";
        "gemini-3.8-flash-high" = thinking "gemini";
        gemini-pro-agent = thinking "gemini";
      };
      launchers = {
        codex.model = "gpt-6.1-sol";
        copilot.model = "claude-sonnet-5-5";
      };
    };
  };

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
        "hunk.review.halfPageDown" = ["ctrl+d" "d"];
        "hunk.review.halfPageUp" = ["ctrl+u" "u"];
      };
    };
  };

  services.flameshot.enable = mkIf osConfig.modules.presets.desktop.enable true;

  # Not `llm-agents.t3code-desktop` — it misses the module's T3 Connect patch.
  modules.programs.t3code = {
    desktopApp = true;
    serve.enable = true;
    package = pkgs.inputs.llm-agents.t3code;
  };
}
