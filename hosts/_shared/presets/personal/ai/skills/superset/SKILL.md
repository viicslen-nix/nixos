---
name: superset
description: Drive the Superset CLI (`superset`) to manage workspaces, projects, tasks, agents, terminals, and automations on the local host server or remote hosts. Use when the user asks to spin up / create a new workspace, start a new task, kick off an agent, register a project, run an automation, or otherwise operate Superset from the terminal.
---

# Superset CLI

The `superset` binary drives the same backend as the Superset desktop app. Use it to manage projects, workspaces, tasks, agents, terminals, and automations.

`@reference.md` holds the full command/flag reference — read it when you need a command not covered below or need exact output shapes.

## First: orient before acting

Superset state is stateful and host-scoped. Before mutating, confirm context:

```bash
superset auth whoami        # confirm signed in + active org
superset status             # is the local host server running?
```

- If not signed in: run `superset auth login` (interactive browser OAuth). In CI/non-interactive, use `SUPERSET_API_KEY` or `superset auth login --api-key sk_live_…`.
- If the local host server is not running and you need `--local`, start it: `superset start --daemon`, then `superset status`.

## Output

The CLI auto-detects this agent environment and defaults to **JSON** output. Pipe through `jq` to extract fields. Use `--quiet` for ID-only output (one per line), handy for piping into other commands.

## Spin up a new workspace (most common request)

A workspace branches off a **project** (a repo registered with the org) on a **host**. Steps:

1. **Find the project:**
   ```bash
   superset projects list        # JSON: [{id, name, slug, repoCloneUrl, ...}]
   ```
   - If the repo isn't registered on this org yet → create it (see below).
   - If it exists in the org but not on this machine → adopt it:
     `superset projects setup <projectId> --local --parent-dir ~/code`
     (or `--import <existing-checkout-path>`).

2. **Create the workspace.** Pick exactly one of `--branch` or `--pr`, and exactly one host target (`--local` or `--host <id>`):
   ```bash
   superset workspaces create \
     --project <projectId> \
     --name "fix-login-bug" \
     --branch fix/login-bug \
     --local
   ```
   - From a PR instead of a branch: `--pr 123` (checks out the verified PR head).
   - New branch off a non-default base: add `--base-branch main`.
   - Spawn an agent immediately: `--agent claude --prompt "Audit the login flow"` (`--prompt` is required with `--agent`). Other presets: `codex`, `cursor`, `amp`, `gemini`, `opencode`, or `superset` for built-in chat.
   - Run a setup command: `--command "bun install && bun test"`.
   - Attach files for the agent: `--attachment ./trace.log` (repeatable).

3. **Open it** in the desktop app (optional): `superset workspaces open <wsId>` (add `--print` to just print the deep link).

### Registering a project (only if it's not in `projects list`)

```bash
# Clone from a Git URL
superset projects create --name "my-app" --local \
  --clone https://github.com/org/my-app.git --parent-dir ~/code

# Or register an existing local checkout
superset projects create --name "my-app" --local --import ~/code/my-app
```
`create` always makes a **new** cloud project. If the repo already exists in the org, use `projects setup <id>` instead to avoid a duplicate.

## Start / manage tasks

```bash
superset tasks list --assignee-me           # what's on my plate
superset tasks statuses list                 # status IDs for filtering/setting
superset tasks get <idOrSlug>
superset tasks create --title "Audit auth flow" --priority high
superset tasks update <idOrSlug> --status-id <id> --pr-url <url>
```

Link a workspace to a task: `superset workspaces update <wsId> --task-id <taskId>`.

If "start a new task" means **do the work** (not just file a tracker entry), the usual flow is: create the task → create a workspace for it → spawn an agent with a prompt → link the workspace to the task. Confirm with the user which they mean if ambiguous.

## Agents & terminals in an existing workspace

```bash
superset agents list --local                                         # available agent presets/instances
superset agents create --workspace <wsId> --agent claude --prompt "…" # start an agent session
superset terminals create --workspace <wsId> --command "bun test"     # one-off command (omit --command for a shell)
```

## Automations (scheduled agent runs)

```bash
superset automations list
superset automations run <id>          # dispatch now (doesn't wait)
superset automations logs <id>
superset automations create --name "Weekday triage" \
  --project <prj> --workspace <ws> \
  --rrule "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;BYHOUR=9;BYMINUTE=0" \
  --prompt-file ./triage.md
```
Schedules are RFC 5545 RRULEs. Pause/resume with `automations pause|resume <id>`.

## Routing rules (important)

- Mutating host commands (`projects create`, `projects setup`, `workspaces create`) **require** an explicit `--local` or `--host <id>` — there is no default.
- `workspaces list` with neither flag is org-wide; add `--local` to scope to this machine.
- `--local` calls go straight to the local host server over loopback (offline-friendly). If it's the local host but the server isn't responding, the CLI errors and points at `superset start` — start it and retry.
- List hosts with `superset hosts list`; switch org with `superset org switch <slug>`.

## Conventions

- Capture IDs from JSON output (`projects list`, `workspaces create`, etc.) and reuse them in follow-up commands rather than guessing.
- Don't invent project/workspace/host IDs — list first, then act.
- Confirm before destructive ops: `workspaces delete <id...>`, `tasks delete`, `automations delete` are not easily reversible.
