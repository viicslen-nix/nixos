{
  flake.modules.nixos.netbird = {
    lib,
    pkgs,
    config,
    ...
  }:
    with lib; let
      name = "netbird";
      namespace = "services";

      cfg = config.modules.${namespace}.${name};
    in {
      options.modules.${namespace}.${name} = {
        enable = mkEnabledOption (mdDoc name);
      };

      config = mkIf cfg.enable (mkMerge [
        {
          services.netbird = {
            enable = true;
            # Loose rp_filter, without which traffic through a NetBird exit node is dropped.
            useRoutingFeatures = "client";
          };

          # NetBird writes its SSH proxy config to ssh_config.d, which NixOS's ssh_config doesn't include.
          programs.ssh.extraConfig = ''
            Include /etc/ssh/ssh_config.d/*.conf
          '';
        }
        # NetBird registers with resolvconf -x, which makes dnsmasq forward everything to NetBird and NetBird back to dnsmasq.
        (mkIf config.services.dnsmasq.enable {
          services.netbird.clients.default = {
            dns-resolver.address = "127.0.0.153";
            config.DisableDNS = true;
          };
          services.dnsmasq.settings.server = ["/netbird.cloud/127.0.0.153"];
        })
        # NetBird's rules (105/110) outrank Tailscale's (52xx), so a NetBird exit node captures the tailnet and tailscaled's own traffic.
        (mkIf config.services.tailscale.enable {
          systemd.services.netbird-tailscale-bypass = let
            # Tailscale's routing table and its fwmark are fixed upstream constants.
            rules = [
              "-4 rule %s priority 100 fwmark 0x80000/0xff0000 lookup main"
              "-6 rule %s priority 100 fwmark 0x80000/0xff0000 lookup main"
              "-4 rule %s priority 101 to 100.64.0.0/10 lookup 52"
              "-6 rule %s priority 101 to fd7a:115c:a1e0::/48 lookup 52"
            ];
            run = verb: suffix: concatMapStrings (r: "ip ${replaceStrings ["%s"] [verb] r}${suffix}\n") rules;
          in {
            description = "Keep tailnet traffic on Tailscale when a NetBird exit node is selected";
            wantedBy = ["multi-user.target"];
            before = ["netbird.service"];
            path = [pkgs.iproute2];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = run "del" " 2>/dev/null || true" + run "add" "";
            preStop = run "del" " || true";
          };
        })
      ]);
    };
}
