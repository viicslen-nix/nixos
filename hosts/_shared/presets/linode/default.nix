{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "linode";
  namespace = "presets";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);
    useNetworkd = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Use networkd to manage networking
      '';
    };
  };

  config = mkIf cfg.enable {
    # Configure networking
    networking = {
      # Disable DHCP globally as we will not need it.
      useDHCP = false;

      # Disable predictable interface names as it Linode has a single interface
      # Optional, but might help with troubleshooting later
      usePredictableInterfaceNames = false;

      # Configure network interfaces
      interfaces.eth0 = {
        useDHCP = true;
        tempAddress = "disabled";
      };

      # Force enable solicitation and receipt of IPv6 Router Advertisements.
      # Allows global IPv6 address auto-configuration with SLAAC
      dhcpcd.IPv6rs = mkIf cfg.useNetworkd == false;

      # Use networkd to manage networking
      useNetworkd = mkIf cfg.useNetworkd true;
    };

    # Configure systemd network
    systemd.network = mkIf cfg.useNetworkd {
      enable = true;

      # Configure network interfaces
      networks."10-wired" = {
        matchConfig.Name = "eth0";
        networkConfig = {
          # Start a DHCP Client for IPv4 Addressing/Routing
          DHCP = "ipv4";

          # Accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          IPv6AcceptRA = true;

          # Disable IPv6 Privacy Extensions
          IPv6PrivacyExtensions = false;
        };

        # Make routing on this interface a dependency for network-online.target
        linkConfig.RequiredForOnline = "routable";
      };
    };

    # Add frequently used tools by Linode support
    environment.systemPackages = with pkgs; [
      inetutils
      mtr
      sysstat
    ];
  };
}
