{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.features.network;
in {
  options.features.network = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable network support";
    };

    hostName = mkOption {
      type = types.str;
      default = "nixos";
      description = "Define your hostname.";
    };

    hosts = mkOption {
      type = types.attrsOf types.str;
      description = "Define host file entries.";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      # Enable networking
      networkmanager.enable = true;

      # Define your hostname.
      hostName = cfg.hostName;

      # Define host file entries.
      extraHosts = concatStringsSep "\n" (mapAttrsToList (name: value: "${value} ${name}") cfg.hosts);
    };
  };
}
