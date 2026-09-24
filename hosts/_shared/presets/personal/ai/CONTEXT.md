# CONTEXT

What is left of the personal AI config after the portable half moved to the
`ai` subflake. `default.nix` now imports that flake's `profile` module and adds
only what cannot travel: a credential, and the one MCP backend that needs it.

Skills, commands, prompts, plugins and the credential-free MCP backends live in
`flakes/ai/content` and `flakes/ai/hmModules/profile.nix`. Their story —
including the three-layer skill precedence and the mattpocock patch anchors —
moved with them.

`modules.programs.ai.skills` and `.mcps` merge across definitions, which is what
lets this file and the `work` preset each add to what the profile sets rather
than replacing it.

## google_stitch authenticates with an API key, not OAuth

Stitch's MCP endpoint is OAuth-protected like the others, but its authorization
server is `accounts.google.com`, which has no `registration_endpoint` — it
needs a `client_id`/`secret` from a Google Cloud OAuth app. So it uses a Stitch
API key instead (Stitch settings → API key → Create key).

## Why the key arrives as a systemd `EnvironmentFile`

`age.secrets.stitch-api-key` is a dotenv file (`STITCH_API_KEY=…`) feeding the
`${…}` in the `google_stitch` backend's header, so the key never lands in the
world-readable `gateway.yaml` in `/nix/store`.

It is fed to the unit as `systemd.user.services.mcp-gateway.Service.EnvironmentFile`,
**not** as the gateway's own `env_files`. home-manager's agenix reports `.path`
as the *literal* `${XDG_RUNTIME_DIR}/agenix/<name>` for a shell to expand, and
the gateway's loader expands only `~`. It would skip the unresolved path, leave
the variable unset, and — `expand_string` having no default — send an **empty**
header, which Stitch answers with a 401. systemd expands `%t` to
`XDG_RUNTIME_DIR` itself, and (with no `-` prefix) refuses to start the unit if
the file is missing, so a failed read is loud instead of silent.
