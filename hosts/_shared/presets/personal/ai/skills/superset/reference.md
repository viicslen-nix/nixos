# Superset CLI — Full Reference

> Beta — flags evolve. `superset update` to stay current. `superset <cmd> --help` for live help.

## Global options (every command)

| Flag | Env | Description |
| --- | --- | --- |
| `--json` | | Print the data payload as formatted JSON. |
| `--quiet` | | One ID per line for arrays; the ID for single objects; JSON fallback. |
| `--api-key <key>` | `SUPERSET_API_KEY` | Use an API key instead of stored OAuth login. |
| `--help, -h` | | Help for the current command. |
| `--version, -v` | | Print version and exit. |

Output defaults to JSON when run under an agent/CI (`CLAUDE_CODE`, `CLAUDECODE`, `CLAUDE_CODE_ENTRYPOINT`, `CODEX_CLI`, `GEMINI_CLI`, `SUPERSET_AGENT`, or `CI` set non-empty) unless `--quiet`.

## State on disk

```
~/.superset/config.json                            # auth, active organization
~/.superset/host/<organizationId>/manifest.json    # host server endpoint + token
~/.superset/host/<organizationId>/host.db          # local host server DB
```
`SUPERSET_HOME_DIR` relocates the whole tree.

## auth

- `superset auth login [--organization <idOrSlug>] [--api-key sk_live_…]` — browser OAuth (or store API key). Loopback callback on 127.0.0.1:51789–51793. Multi-org + no TTY requires `--organization`.
- `superset auth logout` — clear credentials (keeps active-org preference).
- `superset auth whoami` — `{userId, email, name, organizationId, organizationName, authSource}`.

## Host server (this machine)

- `superset start [--daemon] [--port <n>]` — start local host server (binds 127.0.0.1). Returns `{pid, port, organizationId}`. Idempotent if already alive.
- `superset stop` — SIGTERM→SIGKILL, removes manifest. `{running:false}` or `{pid, organizationId}`.
- `superset status` — `{running:false}` / stale `{running:false, stale:true, pid, …}` / running `{running:true, healthy, pid, port, endpoint, organizationId, uptimeSec}`.
- `superset update [--check] [--force] [--version <v>]` — update CLI + host binary. Only in built binaries.

## organization (alias: org)

- `superset org list` — `[{id, name, slug, active}]`.
- `superset org switch <idOrSlug>` — set active org in config.
- `superset org members list [--search/-s <q>] [--limit <n>]` — `[{id, name, email, role}]`.

## projects

A project = a repo registered with the org (one cloud record per repo, shared) + one or more host checkouts.

- `superset projects list` — `[{id, name, slug, repoCloneUrl, githubRepositoryId}]`. Org-wide.
- `superset projects create --name <n> (--local | --host <id>) [--clone <url> --parent-dir <path> | --import <path>]` — always creates a NEW cloud project. Returns `{projectId, repoPath, mainWorkspaceId}`.
- `superset projects setup <id> (--local | --host <id>) [--parent-dir <path> | --import <path>] [--allow-relocate]` — adopt an EXISTING project onto a host without duplicating. URL comes from the cloud record. Idempotent. Returns `{repoPath, mainWorkspaceId}`.

## hosts

- `superset hosts list` — `[{id, name, online}]`. Registration happens via `superset start` per machine.

## workspaces (alias: ws)

Branch-scoped working copies on a host. `--local` → loopback (offline); else cloud+relay.

- `superset ws list [--host <id>] [--local]` — `[{id, name, branch, projectId, projectName, hostId, hostName}]`. No flag = org-wide.
- `superset ws create --project <id> --name <n> (--branch <b> | --pr <n>) (--local | --host <id>) [--base-branch <b>] [--agent <preset|uuid|superset> --prompt <text>] [--command <cmd>] [--attachment <path>…]` — returns Workspace. Exactly one of `--branch`/`--pr`. `--agent` requires `--prompt`.
- `superset ws delete <id…> [--host <id>] [--local]` — `{deleted:[]}`.
- `superset ws update <id> [--name <n>] [--task-id <id> | --clear-task]` — returns Workspace.
- `superset ws open <id> [--print]` — open in desktop app; returns `{id, name, url}`.

## agents

Terminal-agent rows configured on a host (Settings → Agents).

- `superset agents list (--local | --host <id>)` — `[{id, presetId, label, command, args, promptTransport, promptArgs, env, order}]`. First call seeds defaults.
- `superset agents create --workspace <id> --agent <preset|uuid|superset> --prompt <text> [--attachment <path>… | --attachment-id <uuid>…]` — `{kind, sessionId, label}`.

Presets: `claude`, `codex`, `cursor`, `amp`, `gemini`, `opencode` (whichever CLIs are on the host's PATH), or `superset` (built-in chat).

## terminals (alias: term)

- `superset term create --workspace <id> [--command <cmd>] [--cwd <path>]` — `{terminalId, status}`. Omit `--command` for an interactive shell.

## tasks (alias: t)

- `superset t list [--status <id>] [--priority urgent|high|medium|low|none] [--assignee <userId>] [--assignee-me/-m] [--creator-me] [--search/-s <q>] [--limit <n>] [--offset <n>]`.
- `superset t get <idOrSlug>`.
- `superset t create --title <t> [--description <d>] [--priority …] [--assignee <id>] [--status-id <id>] [--estimate <n>] [--due-date <iso>] [--labels a,b,c]`.
- `superset t update <idOrSlug> [--title] [--description] [--priority] [--assignee] [--status-id] [--pr-url <url>] [--estimate] [--due-date] [--labels a,b,c]`.
- `superset t delete <idOrSlug…>` — `{deleted:[], failed:[]}`.
- `superset t statuses list` — `[{id, name, type, position}]`.

## automations (alias: auto)

Scheduled agent runs. Schedules = RFC 5545 RRULE, e.g. `FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;BYHOUR=9;BYMINUTE=0`.

- `superset auto list`.
- `superset auto get <id>` — metadata (prompt omitted).
- `superset auto create --name <n> --rrule <r> (--prompt <text> | --prompt-file <path>) (--project <id> | --workspace <id>) [--timezone <iana>] [--dtstart <iso>] [--host <id>] [--agent <agent>]`. At least one of `--project`/`--workspace`.
- `superset auto update <id> [--name] [--rrule] [--timezone] [--dtstart] [--host] [--project] [--workspace] [--agent] [--mcp-scope a,b,c] [--enabled | --no-enabled]`. Omitting a flag preserves existing value.
- `superset auto prompt get <id>` — print raw prompt body (byte-exact round-trip with set).
- `superset auto prompt set <id> --from-file <path|->` — replace prompt body.
- `superset auto delete <id>` — `{deleted}`.
- `superset auto pause <id>` / `resume <id>` — toggle enabled.
- `superset auto run <id>` — dispatch now, returns `{automationId, runId}` (doesn't wait).
- `superset auto logs <id> [--limit <n>]` — `[{runId, status, scheduled, dispatched, host}]` (max 100).

## Host prerequisites

`git` and `gh` must be on PATH. `gh auth login` (or `GH_TOKEN`/`GITHUB_TOKEN` for CI). Agent CLIs are optional — the host launches whichever are installed.
