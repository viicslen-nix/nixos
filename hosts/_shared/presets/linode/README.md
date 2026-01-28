# Linode Networking Configuration

This NixOS module configures networking for Linode instances. It provides options to enable and configure network settings, including the option to use `systemd-networkd` for managing networking.

**Resources:**

- [Manual network configuration on a Compute Instance](https://techdocs.akamai.com/cloud-computing/docs/manual-network-configuration-on-a-compute-instance)

## Options

### `enable`

- **Type:** `boolean`
- **Default:** `false`
- **Description:** Enable the Linode networking configuration.

### `useNetworkd`

- **Type:** `boolean`
- **Default:** `false`
- **Description:** Use `systemd-networkd` to manage networking.

## Configuration

When the `enable` option is set to `true`, the following configurations are applied:

### Networking

- **Disable DHCP globally:** `useDHCP = false`
- **Disable predictable interface names:** `usePredictableInterfaceNames = false`
- **Configure network interfaces:**
  - `eth0` interface:
    - Enable DHCP: `useDHCP = true`
    - Disable temporary IPv6 addresses: `tempAddress = "disabled"`

- **Force enable solicitation and receipt of IPv6 Router Advertisements:** `dhcpcd.IPv6rs = mkIf cfg.useNetworkd == false`

### Systemd Network

When `useNetworkd` is set to `true`, the following configurations are applied:

- **Use `systemd-networkd` to manage networking:** `useNetworkd = mkIf cfg.useNetworkd true`
- **Enable `systemd-networkd`:** `enable = true`
- **Configure network interfaces:**
  - `10-wired` network:
    - Match interface name: `matchConfig.Name = "eth0"`
    - Network configuration:
      - Start a DHCP client for IPv4 addressing/routing: `DHCP = "ipv4"`
      - Accept Router Advertisements for Stateless IPv6 Autoconfiguration (SLAAC): `IPv6AcceptRA = true`
      - Disable IPv6 Privacy Extensions: `IPv6PrivacyExtensions = false`
    - Make routing on this interface a dependency for `network-online.target`: `linkConfig.RequiredForOnline = "routable"`

### System Packages

Add frequently used tools by Linode support to the system environment:

- `inetutils`
- `mtr`
- `sysstat`

## Usage

To use this module, include it in your NixOS configuration and set the desired options. For example:

```nix
{
  imports = [
    outputs.nixosModules.linode
  ];

  linode.networking.enable = true;
  linode.networking.useNetworkd = true;
}
