# CONTEXT

The `personal` preset. This file holds the reasoning behind `default.nix` and
`home.nix`.

## What lives here

Your own apps, as `home.packages` in `home.nix`: chat, media, notes and
drawing, the phone tools, and nixvim. Coding tools are in `dev`. `default.nix`
keeps only what needs the system: qmk, homarr, localsend, `adbusers`, dictd.

## Desktop gating

qmk, homarr and localsend all default to enabled by their modules, so
`default.nix` sets them to `modules.presets.desktop.enable` explicitly; the GUI
apps in `home.nix` sit in the gated list for the same reason. A headless host
with `personal` gets the CLI set only.

`adbusers` is granted here, not in `base`: android-tools is a personal package,
and a server has no reason to carry the group.

## AI config

What is left of the personal AI config after the portable half moved to the
`ai` subflake. The harnesses and the profile are `dev`'s; `home.nix` imports
only the `ai` module, for the options it sets, and adds what cannot travel: a
credential, the one MCP backend that needs it, and the browser-harness
integration.

Skills, commands, prompts, plugins and the credential-free MCP backends live in
`flakes/ai/content` and `flakes/ai/hmModules/profile.nix`, and their story moved
with them.

`modules.programs.ai.skills` and `.mcps` merge across definitions, which is what
lets this preset and the `work` preset each add to what the profile sets rather
than replacing it.

### google_stitch authenticates with an API key, not OAuth

Stitch's MCP endpoint is OAuth-protected like the others, but its authorization
server is `accounts.google.com`, which has no `registration_endpoint` — it
needs a `client_id`/`secret` from a Google Cloud OAuth app. So it uses a Stitch
API key instead (Stitch settings → API key → Create key).

### Why the key arrives as a systemd `EnvironmentFile`

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
