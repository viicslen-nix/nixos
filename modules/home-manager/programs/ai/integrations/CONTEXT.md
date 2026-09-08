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
