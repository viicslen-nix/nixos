{
  lib,
  config,
  ...
}:
with lib; let
  name = "docker";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "docker");

    nvidiaSupport = mkOption {
      type = types.bool;
      default = false;
      description = "Enable support for NVIDIA GPUs";
    };

    users = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "The users to add to the docker group";
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

    users.users = lib.genAttrs cfg.users (user: {
      extraGroups = ["docker"];
    });

    networking.firewall.trustedInterfaces = [cfg.networkInterface];
    networking.firewall.allowedTCPPorts = cfg.allowTcpPorts;

    hardware.nvidia-container-toolkit.enable = cfg.nvidiaSupport;
  };
}
