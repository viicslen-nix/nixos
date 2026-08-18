{
  flake.modules.nixos.portainer = {
    inputs,
    lib,
    config,
    ...
  }:
    with lib; let
      inherit (inputs.self.lib.containers) mkHostOption mkMkcertDomains mkTraefikLabels;

      name = "portainer";
      namespace = "containers";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        host = mkHostOption "portainer.local" "Portainer";
      };

      config = mkIf cfg.enable {
        networking.hosts."127.0.0.1" = [cfg.host];

        modules.programs.mkcert = mkMkcertDomains config [cfg.host];

        virtualisation.oci-containers.containers = {
          portainer = {
            hostname = "portainer";
            image = "portainer/portainer-ee:latest";
            ports = [
              # "127.0.0.1:8000:8000"
              "127.0.0.1:9443:9443"
            ];
            volumes = [
              "portainer:/data"
              "/var/run/docker.sock:/var/run/docker.sock"
            ];
            extraOptions =
              [
                "--network=local"
              ]
              ++ mkTraefikLabels {
                name = "portainer";
                host = cfg.host;
                port = 9443;
                scheme = "https";
              };
            log-driver = config.modules.containers.settings.log-driver;
          };
        };
      };
    };
}
