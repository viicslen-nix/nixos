{
  lib,
  pkgs,
  users,
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

    storageDriver = mkOption {
      type = types.str;
      default = "overlay2";
      description = "The storage driver to use";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      docker-credential-helpers
    ];

    virtualisation = {
      docker = {
        enable = true;
        autoPrune.enable = true;
        storageDriver = cfg.storageDriver;
      };

      podman.enable = false;

      oci-containers.backend = "docker";
    };

    users.users = lib.genAttrs (attrNames users) (_user: {
      extraGroups = ["docker"];
    });

    networking.firewall.trustedInterfaces = [cfg.networkInterface];
    networking.firewall.allowedTCPPorts = cfg.allowTcpPorts;

    hardware.nvidia-container-toolkit.enable = cfg.nvidiaSupport;
  };
}
