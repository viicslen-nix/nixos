# CONTEXT

The `work` preset. This file holds the reasoning behind `home.nix` — the MCP
wrappers that reach production and the ssh tunnel they ride on.

## What lives here rather than in a host or user file

`core.network.hosts` is the union of every work host's local-dev entries; the
hosts used to carry near-identical copies that drifted (`labreu.test` on one,
`erpnext.test` on another). Everything resolves to loopback, so the extra
names cost a headless host nothing.

The kubectl / `vendor/bin/dep` / sail aliases, the intelephense licence
secret and the `work.neoscode.com` cloudflared `ProxyCommand` are work
concerns, so they live in `home.nix` and not in `users/<name>`. They use
`config.home.homeDirectory` because a shared module has no user variable.
The `dep` alias is `vendor/bin/dep`, not `composer exec -- dep`: home-manager's
`home.shellAliases` reaches every shell, and the per-project binary is what is
wanted.

`home.nix` imports `homeModules.programs.{ai,claude-code}` itself: it configures
both, and `personal` is not guaranteed to be imported beside it.

## `xdgRuntimeDir` exists because mcp-gateway scrubs the environment

mcp-gateway spawns stdio backends with a scrubbed environment — only
`HOME`/`PATH`/`PWD`/`SHLVL`/`TMPDIR`, plus whatever the backend's own `env`
block names. An agenix secret path is `${XDG_RUNTIME_DIR}/agenix/<name>`, so
under the gateway that expands to `/agenix/<name>`, the `cat` fails, and
`export VAR="$(…)"` swallows the failure (bash returns *export's* status, not
the substitution's) — leaving the server running on an *empty* credential.

That is why prod-db died on `Access denied … (using password: NO)` while
grafana just served an empty token and still listed its tools. Re-deriving
`XDG_RUNTIME_DIR` at the top of each wrapper is what makes them work whether
they are spawned by the gateway or by a shell. The wrappers also assign first
and export second, so a failed read trips `set -e` instead of reaching the
server as an empty password.

## prod-db-mcp

Read-only MCP access to the production MariaDB read replica. It brings the SSH
tunnel up (MariaDB binds to the Linode private address only), then serves it
over stdio. The password comes from an agenix secret decrypted at activation,
so MCP clients can spawn this non-interactively — no 1Password unlock prompt —
and it never lands in `~/.claude.json`.

`mcp-toolbox` is Google's MCP server for databases, distributed as a prebuilt
static Go binary, so it needs no patchelf and runs on NixOS as-is.

## grafana-mcp

Same trick as prod-db-mcp: the token can't live in the MCP `env` block (that
lands in a world-readable JSON config, and in the repo), so the wrapper reads
it from the agenix secret at spawn time instead.

## The `db-prod-read-tunnel` ssh host

The tunnel for the read-only MCP database server (`~/.local/bin/prod-db-mcp`).
MariaDB binds to the Linode private address only, so 3306 is unreachable from
outside the datacenter — the `LocalForward` target is that private IP,
`192.168.201.159`. `ExitOnForwardFailure = "yes"` fails the ssh call outright
if the forward can't bind, instead of succeeding and leaving every query to
fail with connection-refused.
