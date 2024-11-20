{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "podman";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc feature);

    user = mkOption {
      type = types.str;
      default = "nixos";
      description = "The user to add to the podman group";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user}.extraGroups = ["podman"];

    virtualisation = {
      containers.enable = lib.mkDefault true;
      oci-containers.backend = "podman";

      docker.enable = false;

      podman = {
        enable = true;

        # Create a `docker` alias for podman, to use it as a drop-in replacement
        dockerCompat = true;

        # Enable the podman socket for docker compatibility
        dockerSocket.enable = true;

        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    environment.systemPackages = with pkgs; [
      dive # look into docker image layers
      podman-tui # status of containers in the terminal
      docker-compose # start group of containers for dev
      podman-compose # start group of containers for dev
      podman-desktop # GUI for podman
    ];
  };
}
