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
bind-mount it. Dropping either breaks those three.

`init-container-network` orders after `docker.service` only on the docker
branch — podman is daemonless, so `podman network create` needs nothing
running. An earlier version required a `podman.service`; that unit is
socket-activated and depending on it just started the API for no reason.

Switching a host's `backend` is not a data migration: podman starts from an
empty `/var/lib/containers/storage`, so images, volumes and the `local` network
are all recreated on first boot.

## What the docker → podman switch actually broke

Three things surfaced only at runtime on the first podman boot, none of them
visible in an eval:

**Short image names.** Every container whose `image` is a bare name
(`traefik:latest`, `redis:alpine`, `percona/percona-server:latest`) failed with
`short-name … did not resolve to an alias and no unqualified-search registries
are defined`. Docker implies `docker.io`; podman refuses to guess. nixpkgs
defaults `virtualisation.containers.registries.search` to `[]`, so the generated
`registries.conf` had `[[registry]]` blocks but no `unqualified-search-registries`
line. Fixed with one `registries.search` in the podman module rather than
qualifying the image in fifteen container modules — the `ghcr.io/…` ones were
already fine.

**dnsmasq owned :53 on podman's bridge.** The containers with fully-qualified
images got further and then died on `aardvark-dns failed to start: failed to
bind udp listener on 10.89.0.1:53: Address already in use`. The traefik module
runs dnsmasq for the `.test` TLD with no `interface`/`bind-interfaces`, so it
binds `0.0.0.0:53` — every interface, the podman bridge gateway included.
Docker never cared because its embedded DNS lives at `127.0.0.11` *inside* the
container netns; podman's aardvark-dns binds the gateway address on the host.
dnsmasq now binds loopback only, which is all `/etc/resolv.conf` ever pointed
at. Side effect worth knowing: containers now resolve `.test` names, because
aardvark forwards to the host's `127.0.0.1` — that never worked under docker.

**`docker compose` narrates itself.** `dockerCompat` makes `docker` podman, so
`docker compose up` is `podman compose`, which shells out to the real
`docker-compose` and prints `>>>> Executing external compose provider … <<<<`
on every invocation. `containersConf.settings.engine.compose_warning_logs`
silences it; the delegation itself is correct and stays.

The general lesson: a backend swap evaluates clean and fails on first boot.
Check `systemctl --failed` and read one journal per distinct error — there were
two different root causes hiding behind ten failed units.

## Two corrections worth keeping

`virtualisation.containers.storage.settings.storage` is *not* a whole-table
option default you have to restate — nixpkgs sets `driver`, `graphroot` and
`runroot` as three separate `lib.mkDefault`s in its `config`, so defining just
`storage.driver` merges and the other two survive. An earlier version of the
podman module restated all three defensively; it was never needed.

`virtualisation.containers.registries.search` is deprecated (slated for removal
in 26.11) and writes the **v1** `[registries.search] registries = […]` shape.
The module writes the v2 key, `settings.unqualified-search-registries`,
directly. That does discard the option's default `registry` list — but those
entries carry only a `location` and no `insecure`/`blocked`/`mirror`, so they
are inert and losing them changes nothing.

## User namespaces (`settings.userns`)

Rootful podman can still map each container's root onto an unprivileged host
UID range, which recovers most of what rootless was wanted for without splitting
the CLI's namespace from the stack's. `settings.userns = "auto"` turns it on.

It is delivered as `CONTAINERS_CONF_OVERRIDE` on each `podman-<name>.service`
rather than as `virtualisation.containers.containersConf.settings.containers.userns`,
because `/etc/containers/containers.conf` is read by **rootless** podman too —
a global `userns = "auto"` there gives an unprivileged user a degenerate
`0 1 1024` mapping (no subuid range to carve from) and breaks every compose
project they run. Per-unit env keeps the blast radius on the rootful stack.
The mechanism was verified with `CONTAINERS_CONF_OVERRIDE` before being wired
in: it produces the same `not enough unused IDs` failure as an explicit
`--userns=auto`, so the key is genuinely honoured.

`auto` carves from the `containers` user's subuid/subgid allocation, which does
not exist by default — podman fails with `not enough unused IDs in user
namespace`. The podman module creates it at 2000000, clear of the 100000-up
ranges nixpkgs hands per-login-user (neoscode 100000, dostov 231072).

Two containers are excluded automatically, by detecting a `docker.sock` or
`podman.sock` bind mount: **traefik** and **homarr**. A mapped root is not host
root, so it cannot read the root-owned engine socket, and traefik's whole job
here is watching it. Anything else that grows a socket mount is skipped without
further edits.

**Why it stays opt-in.** Turning it on offsets ownership *on disk*.
Demonstrated with an explicit map rather than assumed:

    # file written by a container under --uidmap 0:200000:65536
    in-container owner=0   →   host-namespace owner=200000

    # existing root-owned file, read back from a mapped container
    cannot create /data/rootfile: Permission denied


Every **named** volume on a mapped container therefore carries `:idmap`, which
makes the kernel remap ownership at mount time instead of rewriting it on disk.
Verified against a volume seeded to look like the real ones — a `999:999` file
written before the switch:

    without :idmap   owner=65534:65534   (nobody — the breakage)
    with    :idmap   owner=999:999       + writes succeed
    host-side after  owner=999:999       (unchanged — a remap, not a chown)

So no migration, no `chown -R`, and the data is safe if the setting is ever
turned off again. `:idmap` on a container with no user namespace is an identity
map, not an error, so the annotation is unconditional and survives
`userns = null`.

Bind mounts of `/nix/store` paths (buggregator's and qdrant's `config`,
centrifugo's config file) deliberately do **not** get `:idmap`: they are
read-only and world-readable, so a mapped root reads them fine.

## Why the CLI points at the rootful socket

`CONTAINER_HOST`/`DOCKER_HOST` in the podman module aim `podman` and
`docker compose` at the rootful engine. Podman's CLI is rootless by default,
which is a *second* namespace: its own images, volumes and networks, including
its own `local` network on the same 10.89.0.0/24. A compose project started
there is invisible to traefik, which watches the rootful socket — the container
comes up correctly labelled and simply never gets a route.

This was added, reverted, and added back. The revert was right at the time: it
was proposed as "make podman behave like docker", which threw away the rootless
isolation that motivated the switch. What changed is that the isolation now
comes from `settings.userns` — each container's root mapped to its own
unprivileged host range — so pointing the CLI at the rootful engine no longer
costs what it did. Rootless-for-its-own-sake was buying a broken traefik.

The alternative, if rootless compose is ever wanted back, is traefik as a native
NixOS service: it binds 80/443 without lowering
`net.ipv4.ip_unprivileged_port_start`, watches the *rootless* socket with
`providers.docker.usebindportip=true` (needed because the host's route for
10.89.0.0/24 points at the rootful bridge, so a discovered rootless IP is
silently misrouted rather than unreachable), and serves the Nix-declared
services from the file provider instead of labels. Traefik has exactly one
`--providers.docker.endpoint`, so watching both engines at once is not an option.

Consequence worth remembering: these variables are `environment.sessionVariables`,
written to `/etc/set-environment` and sourced by `/etc/profile` — login shells
only. A new terminal tab inherits the old environment; it takes a fresh login.
