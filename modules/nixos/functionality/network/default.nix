{
  lib,
  config,
  ...
}:
with lib; let
  name = "network";
  namespace = "functionality";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
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
      default = {};
      description = "Define host file entries.";
    };

    nameservers = mkOption {
      type = types.listOf types.str;
      default = [ "1.1.1.1" "1.0.0.1" ];
      description = "Define DNS nameservers.";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      # Enable networking
      networkmanager.enable = true;

      # Define your hostname.
      hostName = mkDefault cfg.hostName;

      # Define host file entries.
      extraHosts = concatStringsSep "\n" (mapAttrsToList (name: value: "${value} ${name}") cfg.hosts);

      # Define DNS nameservers.
      nameservers = mkDefault cfg.nameservers;
    };
  };
}
