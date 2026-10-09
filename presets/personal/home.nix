{
  lib,
  pkgs,
  config,
  inputs,
  osConfig,
  ...
}:
with lib; {
  imports = [
    inputs.hunk.homeManagerModules.default
    inputs.ai.homeManagerModules.default
  ];

  age.secrets = {
    avante-anthropic-api-key.file = ../../secrets/avante/anthropic-api-key.age;
    stitch-api-key.file = ../../secrets/stitch/api-key.age;
    cliproxyapi-api-key.file = ../../secrets/cliproxyapi/api-key.age;
  };

  # Not the gateway's `env_files` — it can't expand the path, sending an empty header.
  systemd.user.services.mcp-gateway.Service.EnvironmentFile = "%t/agenix/stitch-api-key";

  modules.programs = {
    claude-code.mods.readable-output.enable = true;

    ai = {
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
        default = true;
        baseUrl = "https://cliproxyapi.tailb6b9b6.ts.net";
        apiKeyFile = config.age.secrets.cliproxyapi-api-key.path;
        models = let
          thinking = api: name: {
            inherit api name;
            reasoning = true;
          };
        in {
          claude-opus-5-5 = thinking "anthropic" "Claude Opus 5.5";
          claude-sonnet-5-5 = thinking "anthropic" "Claude Sonnet 5.5";
          claude-haiku-4-5-20251001 = thinking "anthropic" "Claude Haiku 4.5";
          claude-fable-5-1 = thinking "anthropic" "Claude Fable 5.1";
          "gpt-6.1-sol" = thinking "openai" "GPT-6.1 Sol";
          gpt-6-sol = thinking "openai" "GPT-6 Sol";
          gpt-6-luna = thinking "openai" "GPT-6 Luna";
          "gpt-5.6-sol" = thinking "openai" "GPT-5.6 Sol";
          "gemini-3.8-flash-high" = thinking "gemini" "Gemini 3.8 Flash (High)";
          gemini-pro-agent = thinking "gemini" "Gemini Pro Agent";
        };
        launchers = {
          codex.model = "gpt-6.1-sol";
          copilot.model = "claude-sonnet-5-5";
        };
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

  modules.programs.t3code = {
    enable = true;
    desktopApp = true;
    serve.enable = true;
    package = pkgs.inputs.packages.t3code.nightly;
  };
}
