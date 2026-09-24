{inputs, ...}: {
  imports = [inputs.ai.homeManagerModules.profile];

  age.secrets.stitch-api-key.file = ../../../../../secrets/stitch/api-key.age;
  # Not the gateway's `env_files` — it can't expand the path, sending an empty header.
  systemd.user.services.mcp-gateway.Service.EnvironmentFile = "%t/agenix/stitch-api-key";

  modules.programs.aiProfile.enable = true;

  # Stays here, not in the ai flake: it needs a credential only this host has.
  # Not `oauth.enabled` — accounts.google.com has no registration_endpoint.
  modules.programs.ai.mcps.google_stitch = {
    url = "https://stitch.googleapis.com/mcp";
    headers."X-Goog-Api-Key" = "\${STITCH_API_KEY}";
  };
}
