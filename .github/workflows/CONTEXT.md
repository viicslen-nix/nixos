# Why the cache is shaped this way

garnix used to build and cache the hosts; it [shut
down](https://garnix.io/blog/shutting-down/) in July 2026, after which every
rebuild compiled the locally built packages again.

## Built from the root, not from each subflake

The first idea was a cache per subflake, each built by that repo's own CI.
It cannot hit. Every subflake `follows` the root's nixpkgs, so hosts build
e.g. niri against the root pin, while a subflake's CI would use its own
`flake.lock` (in 2026-10 only `home` matched the root). niri is also
instantiated from the host's `pkgs`, which carries the nixpkgs-wayland overlay
on desktops — no subflake can reproduce that path. So one root workflow asks
the hosts themselves what they would build (`nix build --dry-run` on each
toplevel) and builds exactly those derivations.

## An allowlist, not a full toplevel build

Measured on `dostov-dev` (62 GiB closure): about 24 GiB is not on
cache.nixos.org. 8 GiB of it comes from other caches we already trust, 13 GiB
is vendor binaries repackaged (vscode, cursor, browsers, AppImages — a
download and an unpack, nothing to save), and only about 1.3 GiB is compiled
from source. That last slice fits Cachix's 5 GB free tier; the rest would not,
and pushing unfree binaries to a public cache is redistribution their licences
do not allow. Hence a name allowlist, applied to the dry-run's "will be built"
list, with a mandatory `-<version>` suffix so personal config derivations
(`worktrunk-config`, `emacs-configured`, `opencode-default`) stay out.

Deliberately not allowlisted: `claude-agent-acp` (bundles Anthropic's
proprietary agent SDK), `ghost-backup` (public repo, no licence), the CachyOS
kernel (lantian's attic serves it when up).

`cachix-action` runs with `skipPush`: its post-job hook would upload every
path the job built, including build-only inputs.

## A GitHub App token for the private `work` input

Since the work preset moved to the private `viicslen-nix/work` repo
(2026-10-26), any job that evaluates a host has to fetch it, and the
workflow's own `github.token` can read only this repo, so the fetch returns a
404. Each such job (host evals, cache, host builds) creates a read-only installation token
for `work` from a GitHub App (`vars.APP_CLIENT_ID`, `secrets.APP_PRIVATE_KEY`)
and uses it as nix's `access-tokens`. Public github.com fetches work with that
token too. It expires after an hour, which is fine as long as inputs are
fetched at eval time, at the start of the job. Format & lint never forces
`work`, so it keeps the workflow token. Pull requests from forks get no
secrets, so these jobs fail there.

Workflows triggered by Dependabot read only *Dependabot* secrets, so
`APP_PRIVATE_KEY` is stored twice, as an Actions secret and as a Dependabot
secret (`gh secret set --app dependabot`). Without the second copy every
Dependabot PR fails the required evals with an empty `private-key`. The key
itself is in 1Password (Personal, "viicslen-nix-ci GitHub App private key").
To rotate it, generate a new key in the app's settings, update both secrets
and the 1Password document, then delete the old key there.

## Why setup no longer frees disk space, and why the input cache has one writer

Measured 2026-10-28: `jlumbroso/free-disk-space` took 2–8 minutes per job,
nearly all of setup and more than the actual work in Format & lint, while the
runners already had 86 GB free before cleanup. Evals build nothing and Cache
compiles a GB or two, so only `build-host.yml`, which builds and exports a
whole closure (dostov-dev's is 62 GB), still opts in.

About 4.5 of each eval's 5 minutes went to fetching roughly 100 flake inputs
one by one, not to evaluating them. `~/.cache/nix` holds the fetched trees, so
every job restores it, but only the Cache job saves it. That job dry-runs every
host, so its copy has every input. Jobs running in parallel that all saved
would race for the same key, and the first one to finish (Format & lint, which
fetches the fewest inputs) would leave the cache without most host inputs.
Sources that Nix substitutes straight into `/nix/store` are still downloaded
every run: caching the store would need a third-party action.

## Why every repo pushes itself to GitLab

`gitlab-mirror.yml` exists in each non-archived viicslen-nix repo except
`foundry-vtt` (deliberately not mirrored) and pushes
all branches and tags (with `--prune`) to `nix/<repo>` on gitlab.neoscode.com.
GitHub is the source of truth. GitLab only receives copies. Two simpler options
do not work here. The self-hosted GitLab is CE, and pull mirroring is
Premium-only. GitLab's push mirrors run in the wrong direction, and they used to
fail on an SSH key. Had they ever authenticated, they would have force-pushed a
stale copy over GitHub. The workflow pushes through Cloudflare, which rejects
request bodies over 100 MB. A first push of a large repo has to go over the
LAN instead.

`GITLAB_TOKEN` is a Maintainer group access token on `nix`
(`github-mirror`, `write_repository`), expiring 2027-10-28. It is stored as a
repo secret in each of the 14 mirrored repos. To rotate it, create a new token and `gh secret set` it in
every repo. `main` on GitLab allows force-push because GitHub history has been
rewritten before; `nixos` shared no ancestor with GitLab's copy in 2026-10.
