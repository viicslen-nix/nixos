# cliproxyapi

A thin layer over nixpkgs' `services.cliproxyapi`. It adds agenix-backed keys,
impermanence, and a Traefik route at `https://cliproxy.local`. The `work`
preset enables it.

## Why it listens on every interface

Traefik runs in a container on the `local` bridge (`podman1`, 10.89.0.0/24).
A service bound to `127.0.0.1` is unreachable from there. Binding to the
gateway address alone is fragile, because the bridge may not be up when the
service starts. So it binds `""` (all interfaces). The firewall only opens the
port on the bridge interfaces (`podman+`, or `br-+` under docker), and nothing
else in the firewall exposes it. The `+` wildcard is iptables syntax, and these
hosts use iptables. If they switch to nftables, the wildcard becomes `*`.

Inside the container, `host.containers.internal` resolves to the bridge
gateway (10.89.0.1), which is the address the Traefik route targets. Don't use
`host.docker.internal`: the containers inherit the host's `/etc/hosts`, which
points that name at `127.0.0.1`, the container's own loopback. Only the podman
path has been tested. Docker has no `host.containers.internal`.

Requests that come through Traefik reach the service from the bridge, so the
Management API counts them as remote. That is why `allow-remote = true` is
set. The management key still guards every request.

## Where Traefik reads the route from

The route is a file-provider YAML. Traefik's dynamic directory is a bind mount
of `/var/lib/traefik/dynamic`, and the container has no `/nix/store`. A symlink
into the store would therefore dangle inside the container, so tmpfiles copies
the file there (`C+`) instead.

## State and things Nix does not own

`/var/lib/cliproxyapi` holds the OAuth tokens (the `auth-dir`) and the
downloaded management panel. It is persisted. `config.yaml` is regenerated
from Nix on every service start. Any setting changed in the panel is lost at
the next restart, so put it in `services.cliproxyapi.settings` instead.

Provider logins are a manual, one-time step:

    sudo -u cliproxyapi cliproxyapi -config /var/lib/cliproxyapi/config.yaml --claude-login

Or use the panel's OAuth page. Both keys were generated randomly when this
module was added. Read them with `agenix -d secrets/cliproxyapi/<name>.age`.
