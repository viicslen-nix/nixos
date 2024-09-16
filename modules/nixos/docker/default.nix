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

    nvidiaSupport = mkOption {
      type = types.bool;
      default = false;
      description = "Enable support for NVIDIA GPUs";
    };

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

    allowTcpPorts = mkOption {
      type = types.listOf types.int;
      default = [80 443];
      description = "The TCP ports to allow in the firewall";
    };
  };

  config = mkIf cfg.enable {
    virtualisation = {
      docker.enable = true;
      docker.autoPrune.enable = true;

      podman.enable = false;

      oci-containers.backend = "docker";
    };

    users.users.${cfg.user}.extraGroups = ["docker"];

    networking.firewall.trustedInterfaces = [cfg.networkInterface];
    networking.firewall.allowedTCPPorts = cfg.allowTcpPorts;

    hardware.nvidia-container-toolkit.enable = cfg.nvidiaSupport;
  };
}
