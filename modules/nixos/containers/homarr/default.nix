{
  flake.modules.nixos.homarr = {
    inputs,
    lib,
    config,
    ...
  }:
    with lib; let
      inherit (inputs.self.lib.containers) mkHostOption mkMkcertDomains mkTraefikLabels;

      name = "homarr";
      namespace = "containers";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        host = mkHostOption "home.local" "Homarr";
      };

      config = mkIf cfg.enable {
        networking.hosts."127.0.0.1" = [cfg.host];

        modules.programs.mkcert = mkMkcertDomains config [cfg.host];

        virtualisation.oci-containers.containers = {
          homarr = {
            hostname = "homarr";
            image = "ghcr.io/ajnart/homarr:latest";
            ports = [
              "127.0.0.1:7575:7575"
            ];
            volumes = [
              "homarr-configs:/app/data/configs"
              "homarr-data:/data"
              "homarr-icons:/app/public/icons"
              "/var/run/docker.sock:/var/run/docker.sock"
            ];
            extraOptions =
              [
                "--network=local"
              ]
              ++ mkTraefikLabels {
                name = "homarr";
                host = cfg.host;
                port = 7575;
              };
            log-driver = config.modules.containers.settings.log-driver;
          };
        };
      };
    };
}
