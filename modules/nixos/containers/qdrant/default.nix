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

    host = mkOption {
      type = types.str;
      default = "qdrant.local";
      description = "Hostname for Qdrant";
    };
  };

  config = mkIf cfg.enable {
    networking.hosts."127.0.0.1" = [cfg.host];

    # Auto-configure mkcert for this container's host
    modules.programs.mkcert =
      mkIf (
        (hasAttr "modules" config)
        && (hasAttr "programs" config.modules)
        && (hasAttr "mkcert" config.modules.programs)
        && config.modules.programs.mkcert.enable
      ) {
        domains = [cfg.host];
      };

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
          "qdrant-data:/qdrant/storage"
          "${builtins.toString ./config}:/qdrant/config"
        ];
        log-driver = config.modules.containers.settings.log-driver;
      };
    };
  };
}
