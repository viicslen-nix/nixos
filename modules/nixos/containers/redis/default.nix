{
  lib,
  config,
  ...
}:
with lib; let
  name = "redis";
  namespace = "containers";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    host = mkOption {
      type = types.str;
      default = "redis.local";
      description = "Hostname for Redis";
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
      redis = {
        hostname = "redis";
        image = "redis:alpine";
        ports = [
          "127.0.0.1:6379:6379"
        ];
        volumes = [
          "redis:/data"
        ];
        extraOptions = [
          "--network=local"
        ];
        log-driver = config.modules.containers.settings.log-driver;
      };
    };
  };
}
