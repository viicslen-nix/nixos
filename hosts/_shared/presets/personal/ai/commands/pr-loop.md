Prepare the current branch for review and keep driving the PR to approval.

Workflow:

1. Review the current repo instructions and inspect git status first.
2. Create the initial commit exactly like the standalone `commit` command: separate changes into logical groups and commit them.
3. Push the current branch.
4. Create a pull request if one does not already exist for the branch. If one already exists, reuse it.
5. Watch the PR for new feedback from **every** reviewer — human reviewers, review threads, review states, inline comments, issue comments, and any bot (`coderabbitai`, `github-advanced-security`, `sonarcloud`, `codecov`, `renovate`, custom org bots, …). Do not filter by author; a finding counts no matter who left it.
6. When new comments arrive, verify each finding against the current code before changing anything. Drop the ones that are outdated, already fixed, purely stylistic noise the repo does not follow, or wrong — note the reason, you will reply with it later.
7. Group the surviving findings into fix units. One fix unit = one distinct change plus the exact set of files it will touch. Merge two findings into the same unit when they touch a common file or are two symptoms of one root cause.
8. Dispatch the units (see "Parallel fixes" below), then push every resulting commit in a single push.
9. Answer every finding **inside its own review thread** — what was fixed and where, or why it was skipped. Never as a general PR comment, never as a reply to the review body. Leave every thread open: resolving is the reviewer's call, or another human's.
10. Keep polling and repeat verify -> group -> fix -> single push per batch.
11. Stop only when no outstanding comment needs action and the PR is approved (by a human or by whichever bot gates the repo).

Parallel fixes:

- Units whose file sets are disjoint run **concurrently**, one subagent per unit, all launched in a single message.
- Units that share a file are **not** parallel. Chain them into one subagent that handles them in sequence, or run them yourself after the parallel batch returns. Two agents editing one file will clobber each other.
- If the repo has fewer than three units, or every unit touches the same area, skip the fan-out and do the work inline. Spawning agents costs more than it saves on small batches.
- Give each subagent: the verbatim comment(s), the reviewer, the file/line hints, the file set it owns, and the instruction that it owns those files exclusively and must not touch anything else.
- Each subagent: investigates the finding against current code, makes the smallest correct change, runs whatever targeted check the repo offers for that code, then commits **only its own files** with `git commit -m <msg> -- <path>…` (path-scoped, so it never picks up another agent's work). Never `git add -A`, never `git add -u`, never `git push`.
- `.git/index.lock` contention is expected when commits land at once. A subagent that hits it waits a second and retries, up to a few times.
- A subagent reports back: what it changed, the commit sha, or that the finding turned out to be invalid and it committed nothing.
- After every subagent returns, review the combined diff yourself before pushing. Agents can be individually right and collectively wrong.

Replying in-thread:

- A skipped or wrong finding needs an answer where the reviewer left it, in the thread hanging off that file and line. `gh pr comment` posts to the conversation tab and is the wrong tool — it does not reach any thread.
- Reply to an inline comment with
  `gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies -f body='…'`,
  using the `id` of the **first** comment in that thread (the one the reviewer opened it with; a reply's own id will not do).
- Never resolve a thread. Reply and leave it open — the reviewer who raised it, or another human, decides when it is settled. `resolveReviewThread` is off limits.
- Enumerate open threads with
  `gh api graphql -f query='{repository(…){pullRequest(number:N){reviewThreads(first:100){nodes{id isResolved comments(first:1){nodes{databaseId path line body author{login}}}}}}}}'`.
  `gh pr view` flattens them and loses the thread grouping. Skip the nodes where `isResolved` is already true.
- Only a review's top-level summary body, which has no file or line, has no thread to answer in. That one, and only that one, gets a plain PR comment.
- Say which commit carries the fix, or state the concrete reason for skipping (already fixed in `<sha>`, the code does X not Y, the repo deliberately does it this way). A bare "done" leaves the next reader guessing.

Operating rules:

- Prefer `gh` for PR discovery, creation, review inspection, and comment polling. `gh api` reaches the review-thread and resolution endpoints the porcelain commands do not.
- Treat line numbers in review comments as hints only.
- Keep changes minimal — fix the finding, not the surrounding code.
- One push per batch, after all fixes for that batch are committed. Never push mid-batch.
- If a required fix is genuinely ambiguous or blocked, ask one brief question instead of guessing.
