# CONTEXT

The AI-harness config for the `personal` preset — skills, commands and MCP
backends. This file holds the reasoning behind `default.nix`; the local skill
deltas have their own [CONTEXT.md](./skill-patches/CONTEXT.md).

## Where skills come from, and in what order

`skills` is three layers, last wins:

1. `upstreamSkills` — taken verbatim from `github:mattpocock/skills` via
   `selectFromInput`, curated by name because that repo carries more than we
   want (`in-progress/`, `misc/`, `deprecated/`).
2. `patchedSkills` — the same upstream skills with the local edits in
   `./skill-patches` rewritten in, so `just update-input mattpocock-skills`
   keeps flowing and a reword that moves an anchor fails the build instead of
   silently reverting.
3. `mkSkillAttrSet ./skills` — a local directory, which shadows either of the
   layers above outright. It also holds the vendored collections
   (`just vendor-skills`), which are plain checked-in skills as far as this is
   concerned.

One upstream path is worth remembering: `writing-for-agents` was renamed from
`writing-great-skills` and had its `GLOSSARY.md` split into `SKILL-MECHANICS.md`
(mattpocock/skills 1fc6573e), so the key here changed with it.

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
