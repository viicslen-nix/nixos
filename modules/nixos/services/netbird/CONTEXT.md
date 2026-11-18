# CONTEXT

NetBird runs beside Tailscale, on NetBird Cloud, as a trial. The account's peer
range is `10.77.0.0/16`: NetBird's default 100.64/10 overlaps Tailscale's, and
Tailscale's `ts-input` rule drops 100.64/10 packets that arrive on any other
interface.

## DNS: `DisableDNS` when dnsmasq runs

Hosts that run dnsmasq (the traefik container module enables it) resolve
through 127.0.0.1, and dnsmasq takes its upstreams from openresolv. NetBird
registers with `resolvconf -x` (exclusive), so dnsmasq forwarded everything to
NetBird while NetBird used 127.0.0.1 as its upstream: a loop, and every lookup
failed. Denying `wt0` in openresolv only removed NetBird's nameserver, and
because the exclusive flag stayed, dnsmasq was left with no upstream at all.
So NetBird is kept out of the host's DNS entirely (`DisableDNS`), its resolver
is pinned to 127.0.0.153, and dnsmasq forwards only `netbird.cloud` to it.

## Rule order: `netbird-tailscale-bypass`

NetBird's policy rules are at priorities 105 (main table, suppressing the
default route) and 110 (everything not carrying NetBird's own mark goes to its
table 7120). Tailscale's are at 5210–5270, and tailnet routes exist only in
Tailscale's table 52. Once a NetBird exit node puts a default route into 7120,
tailnet destinations (100.64/10, MagicDNS at 100.100.100.100,
fd7a:115c:a1e0::/48) and tailscaled's own fwmarked traffic leave through the
exit. On 2026-11-18 home-desktop lost CLIProxyAPI while the Mullvad exit was
selected: tailscaled's STUN endpoint turned into the Mullvad IP and its
control long-poll timed out. The unit's rules at 100/101 put Tailscale's
traffic back on `main` and table 52 before NetBird sees it. Without an exit
selected they change nothing.

The route selection survives `netbird down`: it lives in
`/var/lib/netbird/state.json` (`routeselector_state`), so reconnecting puts a
selected exit straight back on.
