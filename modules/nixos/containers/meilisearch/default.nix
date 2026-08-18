{
  flake.modules.nixos.meilisearch = {
    inputs,
    lib,
    config,
    ...
  }:
    with lib; let
      inherit (inputs.self.lib.containers) mkHostOption mkMkcertDomains mkTraefikLabels;

      name = "meilisearch";
      namespace = "containers";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        host = mkHostOption "meilisearch.local" "Meilisearch";
      };

      config = mkIf cfg.enable {
        networking.hosts."127.0.0.1" = [cfg.host];

        modules.programs.mkcert = mkMkcertDomains config [cfg.host];

        virtualisation.oci-containers.containers = {
          meilisearch = {
            hostname = "meilisearch";
            image = "getmeili/meilisearch:latest";
            ports = [
              "127.0.0.1:7700:7700"
            ];
            volumes = [
              "meiliseach:/meili_data"
            ];
            extraOptions = [
              "--network=local"
            ];
            environment = {
              MEILI_NO_ANALYTICS = "true";
            };
            log-driver = config.modules.containers.settings.log-driver;
          };
        };
      };
    };
}
