# CONTEXT

The `work` preset. This file holds the reasoning behind `home.nix` — the MCP
wrappers that reach production and the ssh tunnel they ride on.

## What lives here

Only what the employer provides: the shared servers and their ssh hosts, the
production MCP wrappers and their secrets, the mkcert root CA, cloud CLIs
(`awscli`, `linode-cli`), the company skills and commands, and the
`work.neoscode.com` cloudflared `ProxyCommand`. General coding tools, the AI
harnesses and the local container stack are in `dev`, which every work host
also lists.

`core.network.hosts` keeps the work servers and the work projects' `.test`
names; the generic `*.local` service names are in `dev`. All of them resolve to
loopback except the servers, so the extra names cost a headless host nothing.
The hosts used to carry near-identical copies that drifted (`labreu.test` on one,
`erpnext.test` on another), which is why they live in a preset at all.

`home.nix` imports `inputs.ai.homeManagerModules.ai` itself, for the
`modules.programs.ai` options it sets (MCPs, skills, jev). The import is keyed,
so it dedupes against `dev`'s, and `work` stays importable without it. The
mkcert module is imported for the same reason; `dev` imports it too.

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

## discord-logs-mcp

Reads the app's production log channels in Discord. It uses its own bot,
*MyListerHub Logs*, rather than the app's bot. A Discord bot has exactly one
token, and its permissions come from guild roles, not the token, so read-only
needs a separate bot. It holds View Channel + Read Message History only, with
Send Messages denied on the category (bots inherit `@everyone`), and has the
Message Content intent on. Without that intent, Discord returns embeds and
attachments empty over REST too, and that is where the log text lives.

`@discord-mcp/cli` is the server because it returns full embeds and attachment
URLs; `mcp-discord` and `@quadslab.io/discord-mcp` return only counts.
`MCP_CATEGORIES=messages` cuts the advertised tools from 221 to 22, and
`MCP_WRITE_MODE=preview` turns any write into a no-op. Both are set in the
wrapper rather than the `env` block so they hold however the script is
spawned. It is not packaged, so it runs through a version-pinned `npx`, with the
npm cache moved under XDG.

## The `db-prod-read-tunnel` ssh host

The tunnel for the read-only MCP database server (`~/.local/bin/prod-db-mcp`).
MariaDB binds to the Linode private address only, so 3306 is unreachable from
outside the datacenter — the `LocalForward` target is that private IP,
`192.168.201.159`. `ExitOnForwardFailure = "yes"` fails the ssh call outright
if the forward can't bind, instead of succeeding and leaving every query to
fail with connection-refused.
