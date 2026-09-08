# CONTEXT

What `modules.programs.claude-code` owns, and the reasoning behind the settings
it pins.

## Scope

Global Claude Code preferences — the whole of `~/.claude/settings.json` apart
from the hooks, which each integrating module contributes for itself
(`modules.programs.ai` for mempalace/superset, `modules.programs.herdr`).

Claude Code rewrites this file itself (`/config`, model switches), as do the
mempalace/ponytail/superset hook installers. Once home-manager owns it those
runtime edits land in `settings.json.backup` and are dropped on the next
activation, so change settings here rather than in the TUI.

That is also why `home.file.".claude/settings.json".force` is set: Claude Code
and the hook installers replace the symlink with a real file at runtime, so
activation backs it up every time, and without `force` the next one aborts on
the stale `settings.json.backup`.

## `autoCompactWindow = 500000`

Auto-compact at half the 1M window instead of the model-tuned default. The
effective threshold is min(this, the model's max context) less a summary buffer.
`CLAUDE_CODE_AUTO_COMPACT_WINDOW` outranks it, and `/autocompact auto` returns
to the default.

## `statusLine.command`

A store path, not `npx -y ccstatusline@latest`: npx re-resolves the version
against the registry on every render, so the statusline paid a network
round-trip and an `npm exec` process per refresh, in every session at once.
