{
  lib,
  pkgs,
  config,
  options,
  users,
  inputs,
  ...
}:
with lib;
with inputs.self.lib; let
  name = "mullvad";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
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

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = with pkgs; [
        mullvad-browser
        mullvad-vpn
        mullvad
      ];

      services.mullvad-vpn = {
        enable = true;
        package = pkgs.mullvad-vpn;
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
    }
    (persistence.mkHmPersistence {
      inherit config options;
      users = attrNames users;
      configDirs = ["Mullvad VPN"];
    })
    (persistence.mkNixosPersistence {
      inherit config;
      directories = ["/etc/mullvad-vpn"];
    })
  ]);
}
