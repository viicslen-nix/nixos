{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.features.mullvad;
in {
  options.features.mullvad = {
    enable = mkEnableOption (mdDoc "mullvad");
    enableExludeIPs = mkOption {
      type = types.bool;
      default = false;
      description = "Enable exluding IPs from the VPN. (Will enable firewall)";
    };
    excludedIPs = mkOption {
      type = types.listOf types.str;
      default = "";
      description = "The IPs to exclude from the VPN.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mullvad-browser
      mullvad-vpn
      mullvad
    ];

    services.mullvad-vpn = {
      enable = true;
      enableExcludeWrapper = true;
    };

    networking = mkIf cfg.enableExludeIPs {
      firewall.enable = true;

      nftables = {
        enable = true;

        tables.excludeTraffic = {
          enable = true;
          family = "inet";
          content = ''
            define EXCLUDED_IPS = {
              ${concatMapStringsSep "\n" (ip: ip + ",") cfg.excludedIPs}
            }

            chain excludeOutgoing {
              type route hook output priority 0; policy accept;
              ip daddr $EXCLUDED_IPS ct mark set 0x00000f41  meta mark set 0x6d6f6c65;
            }
          '';
        };
      };
    };
  };
}
