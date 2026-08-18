{
  flake.modules.nixos.local-ai = {
    inputs,
    lib,
    config,
    ...
  }:
    with lib; let
      inherit (inputs.self.lib.containers) mkHostOption mkMkcertDomains mkTraefikLabels;

      name = "local-ai";
      namespace = "containers";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);

        host = mkHostOption "ai.local" "Local AI";
      };

      config = mkIf cfg.enable {
        networking.hosts."127.0.0.1" = [cfg.host];

        modules.programs.mkcert = mkMkcertDomains config [cfg.host];

        virtualisation.oci-containers.containers = {
          local-ai = {
            hostname = "local-ai";
            image = "localai/localai:latest-aio-gpu-nvidia-cuda-12";
            volumes = [
              "localai-models:/build/models"
            ];
            environment = {
              DEBUG = "true";
            };
            extraOptions =
              [
                "--network=local"
                "--device=nvidia.com/gpu=all"
              ]
              ++ mkTraefikLabels {
                name = "localai";
                host = cfg.host;
                port = 8080;
              };
            log-driver = config.modules.containers.settings.log-driver;
          };
        };
      };
    };
}
