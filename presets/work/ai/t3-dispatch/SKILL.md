---
name: t3-dispatch
description: Scripts behind the scheduled MyListerHub triage prompts (CI Health Check, Discord exception triage) — new red CI runs since the last triage, and open PRs/worktrees already touching an error. Use when such a prompt names them.
---

# T3 dispatch helpers

State lives in `${XDG_STATE_HOME:-~/.local/state}/t3-dispatch/`. Both scripts default to `FmTod/mylisterhub-main-app`; pass `-R owner/repo` for another.

- `scripts/ci-red-runs` prints a JSON array of red workflows (latest completed run is `failure`/`timed_out`) on `master`, the newest `releases/*` branch, and the scheduled workflows (`tia-baseline`, `openwiki-update`, `build-images`, `create-release`), skipping runs already marked. Each entry carries the failed jobs/steps and a trimmed `--log-failed` excerpt. A summary of every red workflow, marked or not, goes to stderr. `scripts/ci-red-runs --mark RUN_ID...` records runs as triaged.
- `scripts/inflight TERM...`, run inside the repo checkout, prints `{term: {prs, worktrees}}`: open PRs whose title, branch, body or changed files contain the term, and local worktrees whose changes since `origin/master` (committed or not) name or contain it. Pass short class names, file paths and test names, not FQCNs. It doesn't fetch, so a stale `origin/master` can only add matches.

New Discord errors come from the `discord-logs` skill's `scripts/discord-errors`.
