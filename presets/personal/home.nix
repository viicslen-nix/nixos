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
      discordo
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

      # Office & notes
      onlyoffice-desktopeditors
      obsidian
      drawing
      drawio

      # Browsers
      luakit

      # Keyboard
      vial
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
      proxy.apiKeyFile = config.age.secrets.cliproxyapi-api-key.path;
    };
  };

  services.flameshot.enable = mkIf desktop true;
}
