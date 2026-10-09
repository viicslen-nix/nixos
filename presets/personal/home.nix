{
  lib,
  pkgs,
  config,
  inputs,
  osConfig,
  ...
}:
with lib; let
  desktop = osConfig.modules.presets.desktop.enable;
in {
  imports = [inputs.ai.homeManagerModules.ai];

  home.packages = with pkgs;
    [
      # Editor
      pkgs.inputs.nixvim.default

      # Terminal
      yazi
      asciinema
      dict

      # Phone
      android-tools

      # Chat
      nchat
    ]
    # GUI apps only on graphical hosts (excluded on WSL/headless).
    ++ lib.optionals desktop [
      # Phone
      scrcpy
      qtscrcpy

      # Chat
      legcord
      discord
      ferdium

      # Media
      ytmdesktop
      kooha

      # Notes & drawing
      obsidian
      drawing
      drawio

      # Browsers
      luakit
    ];

  age.secrets = {
    avante-anthropic-api-key.file = ../../secrets/avante/anthropic-api-key.age;
    stitch-api-key.file = ../../secrets/stitch/api-key.age;
    cliproxyapi-api-key.file = ../../secrets/cliproxyapi/api-key.age;
  };

  # Not the gateway's `env_files` — it can't expand the path, sending an empty header.
  systemd.user.services.mcp-gateway.Service.EnvironmentFile = "%t/agenix/stitch-api-key";

  modules.programs = {
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

  services.flameshot.enable = mkIf desktop true;
}
