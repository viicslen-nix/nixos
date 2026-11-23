{config, ...}: {
  # `personal` normally provides this secret; this host doesn't list it.
  age.secrets.cliproxyapi-api-key.file = ../../secrets/cliproxyapi/api-key.age;
  modules.programs.ai.proxy.apiKeyFile = config.age.secrets.cliproxyapi-api-key.path;
}
