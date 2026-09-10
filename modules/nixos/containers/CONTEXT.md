# containers

`modules.containers.settings` is the single place the container engine is
configured. `backend` picks the engine; `nvidiaSupport`, `storageDriver` and
`allowTcpPorts` are engine-agnostic and read by whichever of
`programs.docker` / `programs.podman` is active. Both program modules default
their `enable` to `backend == "<self>"`, so importing both is safe and a host
flips one option — that is what the `work` preset does.

Only `networkInterface` stayed per-module, because the value genuinely differs
(`docker0` vs `podman0`).

`storageDriver` defaults to `null` rather than to a driver name because the two
engines spell the same driver differently: docker's `overlay2` is
containers-storage's `overlay`. `null` means "each engine keeps its own
default"; a real value (`"btrfs"` on the two btrfs hosts) is passed through
unchanged, which works because nixpkgs' podman is built against `btrfs-progs`
and so has the btrfs graphdriver compiled in.

The two program modules stay separate rather than becoming one module with a
`backend` option because what's left after hoisting is genuinely disjoint
plumbing: `virtualisation.docker.storageDriver` vs a `storage.conf` table, and
persistence on `/var/lib/docker` + `~/.docker` vs `/var/lib/containers` +
`~/.local/share/containers`.

The podman module leans on `dockerCompat` + `dockerSocket.enable`: that is what
keeps `/var/run/docker.sock` working for traefik, portainer and homarr, which
bind-mount it. Dropping either breaks those three. Note also that defining
`virtualisation.containers.storage.settings` at all discards the upstream
default table, so the module restates `graphroot`/`runroot` — hence the `mkIf`
that leaves the option untouched when `storageDriver` is `null`.

`init-container-network` orders after `docker.service` only on the docker
branch — podman is daemonless, so `podman network create` needs nothing
running. An earlier version required a `podman.service`; that unit is
socket-activated and depending on it just started the API for no reason.

Switching a host's `backend` is not a data migration: podman starts from an
empty `/var/lib/containers/storage`, so images, volumes and the `local` network
are all recreated on first boot.
