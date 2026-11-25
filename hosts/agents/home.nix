{
  config,
  lib,
  ...
}: {
  # `personal` normally provides this secret; this host doesn't list it.
  age.secrets.cliproxyapi-api-key.file = ../../secrets/cliproxyapi/api-key.age;
  modules.programs.ai.proxy.apiKeyFile = config.age.secrets.cliproxyapi-api-key.path;

  # Keep null: gh must own a writable hosts.yml here.
  modules.programs.gh.user = lib.mkForce null;
}
