# CONTEXT

`root@openclaw` is a Debian 13 LXC on Proxmox (2 vCPU, 4 GB) running OpenClaw.
It is not NixOS: Nix is installed multi-user, and the host is `kind = "home"`
in `hosts/default.nix`, so `parts/hosts.nix` builds it as a standalone
home-manager configuration (`homeConfigurations."root@openclaw"`) from the `ai`
preset plus this directory's `home.nix`, which holds only the tailnet proxy.

## Reaching CLIProxyAPI

The container has no `/dev/net/tun`, so tailscaled runs with
`--tun=userspace-networking`: it is on the tailnet, but no other process can
reach a tailnet address or resolve a `*.ts.net` name. tailscaled is started
with a local proxy instead (`/etc/default/tailscaled`, backup beside it):

```
FLAGS="--socks5-server=127.0.0.1:1055 --outbound-http-proxy-listen=127.0.0.1:1055"
```

The home config points `HTTPS_PROXY`/`HTTP_PROXY` there (plus
`NODE_USE_ENV_PROXY=1` for Node's fetch), and repeats it in Claude Code's
`settings.env` so it holds however `claude` is launched. Adding TUN to the LXC
on the Proxmox host would make the proxy unnecessary.

## Hand-made state on the box

None of this is declarative; redo it on a rebuilt container.

- `/root/.config/cliproxyapi/api-key` (0600): the decrypted
  `secrets/cliproxyapi/api-key.age`. The box is not an agenix recipient.
- `/etc/nix/nix.conf`: `experimental-features = nix-command flakes`,
  `trusted-users = root`.
- `/root/.profile` and `/root/.bashrc` source `hm-session-vars.sh`, and
  `.bashrc` ends by prepending `~/.nix-profile/bin`. The incoming SSH
  environment already carries `__ETC_PROFILE_NIX_SOURCED=1`, so
  `/etc/profile.d/nix.sh` returns early and never adds it; and earlier
  non-Nix installs (`~/.opencode/bin`, `~/.local/bin/codex`, bun) would
  otherwise shadow the profile's harnesses.
- `loginctl enable-linger root`, for the `mcp-gateway` user service. Reach the
  user manager with `XDG_RUNTIME_DIR=/run/user/0` set; Tailscale SSH sessions
  lack it.

## Deploying

Build here, not on the box — 4 GB will not evaluate the profile:

```bash
nix build --print-out-paths '.#homeConfigurations."root@openclaw".activationPackage'
nix copy --no-check-sigs --to 'ssh-ng://root@openclaw?remote-program=/nix/var/nix/profiles/default/bin/nix-daemon' <out>
ssh root@openclaw 'HOME_MANAGER_BACKUP_EXT=hm-bak <out>/activate'
```

`remote-program` is needed because a non-interactive SSH session has no Nix on
`PATH`, and `--no-check-sigs` because locally built paths carry no signature
the box trusts.
