{
  flake.modules.nixos.nginx-proxy-manager = {
    inputs,
    lib,
    config,
    ...
  }:
    with lib; let
      inherit (inputs.self.lib.containers) mkHostOption mkMkcertDomains mkTraefikLabels;

      name = "nginx-proxy-manager";
      namespace = "containers";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        host = mkHostOption "npm.local" "Nginx Proxy Manager";
      };

      config = mkIf cfg.enable {
        networking.hosts."127.0.0.1" = [cfg.host];

        modules.programs.mkcert = mkMkcertDomains config [cfg.host];

        virtualisation.oci-containers.containers = {
          nginx-proxy-manager = {
            hostname = "npm";
            image = "jc21/nginx-proxy-manager:latest";
            ports = [
              "127.0.0.1:80:80"
              "127.0.0.1:443:443"
              "127.0.0.1:81:81"
            ];
            volumes = [
              "nginx-proxy-manager:/data"
              "letsencrypt:/etc/letsencrypt"
            ];
            extraOptions = [
              "--network=local"
            ];
            log-driver = config.modules.containers.settings.log-driver;
          };
        };
      };
    };
}
