# CONTEXT

Background for the `modules.programs.ai` integrations — the mcp-gateway
backend translation and the settings it leaves alone.

## `mcp-gateway.nix` — `toBackend`

mcp-gateway takes a single shell-ish `command` string (split with shlex), not
command+args, and calls the remote transport `http_url`. Remote endpoints
default to Streamable HTTP unless the URL names the legacy `/sse` transport —
with `streamable_http` off the gateway opens an SSE GET handshake instead, which
every `/mcp` endpoint rejects, and the backend silently never connects. The
computed attrs come first in the merge so anything set on the server itself
still wins.

## `mcp-gateway.nix` — `meta_mcp.warm_start`

Deliberately left unset: an empty list means *every* backend is warm-started,
which is what a browser-OAuth backend needs (its consent handshake runs at
startup instead of stalling the first tool call). Naming backends there would
narrow warm-start to just those.

## `mcp-gateway.nix` — `MCP_GATEWAY_CONFIG`

`list`/`get`/`add`/`remove`/`doctor` each carry their own `-c`, defaulting to a
cwd-relative `gateway.yaml`; only `serve` falls back to
`~/.config/mcp-gateway/gateway.yaml`. This env var is the one knob that points
all of them at the generated config from any directory.

## `openwiki.nix` — why an integration, not its own module

OpenWiki's `integrations install <host>` does exactly two things: add an
`openwiki mcp --host <host>` stdio server to the host's MCP config, and copy
`integrations/openwiki/SKILL.md` into its skills directory. Both of those are
already `modules.programs.ai`'s job, and its writes land in `~/.claude.json` /
`~/.claude/skills`, which this repo owns and overwrites on activation — so the
installer would be undone every rebuild. Declaring the pair here fans it out to
every enabled CLI for free. The CLI itself (`openwiki --init`, `visualize`) is
an ordinary package and carries no configuration, so it needs no module of its
own; the integration puts it on `PATH`.
