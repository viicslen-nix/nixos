# CONTEXT

`agents` is a headless Proxmox LXC for running AI agents, driven from T3 Code
on the workstations. It is a real NixOS host (`base` + `dev` + `work`) and
replaced `openclaw`, a Debian container that got a standalone home-manager
profile pushed to it from a workstation.

## How it updates

It pulls its own config from GitHub: `system.autoUpgrade` runs nightly against
`git+https://github.com/viicslen-nix/nixos#agents`, and `nh os switch` on the
box uses the same ref. Only pushed commits reach it, submodule commits
included.

The ref must be `git+https://`. `github:` fetches a tarball without
submodules, so every `path:./flakes/*` input comes up empty. The private
`work`/`homelab` inputs are fetched with base's agenix GitHub token, so the
box only updates once it can decrypt secrets.

The box evaluates `base + dev + work` itself, which is why it gets more memory
than its idle load needs.

## First boot

The container is created from this host's own image:

```bash
nix build '.#nixosConfigurations.agents.config.system.build.tarball'
```

`proxmox-lxc.nix` hands networking to networkd (DHCP from Proxmox), so the
`core.network` NetworkManager is forced off. The container needs TUN for
tailscaled and NetBird, `nesting`/`keyctl` for Docker, and `fuse` for envfs.

## Hand-made state

None of this is declarative; redo it on a rebuilt container.

- `/home/neoscode/.ssh/agenix`: the portable agenix key every secret is
  encrypted to. Nothing decrypts until it is there.
- `tailscale up --ssh` and `netbird up` logins.
- `t3 connect link` as `neoscode`, which registers the server with T3 Connect;
  the authorization lives in the T3 Code state dir.
