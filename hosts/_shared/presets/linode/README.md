# Linode preset

Networking for Linode instances. Applied unconditionally to every host that
lists `linode` in its `presets`; there is no `enable` switch.

**Resources:**

- [Manual network configuration on a Compute Instance](https://techdocs.akamai.com/cloud-computing/docs/manual-network-configuration-on-a-compute-instance)

## Options

### `modules.presets.linode.useNetworkd`

- **Type:** `boolean`
- **Default:** `false`
- **Description:** Manage networking with `systemd-networkd` instead of
  scripted networking + dhcpcd.

## What it configures

### Always

- `networking.useDHCP = false`, `usePredictableInterfaceNames = false` (Linode
  has a single interface, `eth0`)
- `networking.interfaces.eth0`: `useDHCP = true`, `tempAddress = "disabled"`
- Linode support tooling in `environment.systemPackages`: `inetutils`, `mtr`,
  `sysstat`

### `useNetworkd = false` (default)

- `networking.dhcpcd.IPv6rs = true` — solicit and accept IPv6 Router
  Advertisements so SLAAC assigns the global address.

### `useNetworkd = true`

- `networking.useNetworkd = true`, `systemd.network.enable = true`
- `systemd.network.networks."10-wired"` on `eth0`: `DHCP = "ipv4"`,
  `IPv6AcceptRA = true`, `IPv6PrivacyExtensions = false`,
  `RequiredForOnline = "routable"`

## Usage

Add the preset to the host in `hosts/default.nix`, then optionally:

```nix
modules.presets.linode.useNetworkd = true;
```
