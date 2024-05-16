{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.features.docker;
in {
  options.features.docker = {
    enable = mkEnableOption (mdDoc "docker");

    user = mkOption {
      type = types.str;
      default = "nixos";
      description = "The user to add to the docker group";
    };

    networkInterface = mkOption {
      type = types.str;
      default = "docker0";
      description = "The network interface to allow in the firewall";
    };
  };

  config = mkIf cfg.enable {
    virtualisation = {
      docker.enable = true;

      podman.enable = false;

      oci-containers.backend = "docker";
    };

    users.users.${cfg.user}.extraGroups = ["docker"];

    networking.firewall.trustedInterfaces = [ cfg.networkInterface ];
    networking.firewall.interfaces.${cfg.networkInterface}.allowedTCPPorts = [ 80 443 ];
  };
}
