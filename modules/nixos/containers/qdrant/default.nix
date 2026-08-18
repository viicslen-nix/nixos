{
  flake.modules.nixos.qdrant = {
    inputs,
    lib,
    config,
    ...
  }:
    with lib; let
      inherit (inputs.self.lib.containers) mkHostOption mkMkcertDomains mkTraefikLabels;

      name = "qdrant";
      namespace = "containers";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        host = mkHostOption "qdrant.local" "Qdrant";
      };

      config = mkIf cfg.enable {
        networking.hosts."127.0.0.1" = [cfg.host];

        modules.programs.mkcert = mkMkcertDomains config [cfg.host];

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
    };
}
