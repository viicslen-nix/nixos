{
  lib,
  config,
  ...
}:
with lib; let
  name = "qdrant";
  namespace = "containers";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      qdrant = {
        hostname = "qdrant";
        image = "qdrant/qdrant:latest";
        ports = [
          "127.0.0.1:6333:6333"
          "127.0.0.1:6334:6334"
        ];
        extraOptions = [
          "--network=local"
        ];
        volumes = [
          "${builtins.toString ./config}:/app/runtime/configs"
        ];
        log-driver = config.modules.containers.settings.log-driver;
      };
    };
  };
}
