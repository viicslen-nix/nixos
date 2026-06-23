Prepare the current branch for review and keep driving the PR to approval.

Workflow:

1. Review the current repo instructions and inspect git status first.
2. Create the initial commit exactly like the standalone `commit` command: separate changes into logical groups and commit them.
3. Push the current branch.
4. Create a pull request if one does not already exist for the branch. If one already exists, reuse it.
5. Watch the PR for new review feedback using GitHub tools, including review threads, review states, and bot feedback such as `coderabbitai`, `coderabbit[bot]`, and `coderabbitai[bot]`.
6. When new review comments arrive, verify each finding against the current code before changing anything.
7. Apply the smallest correct fix for each still-valid finding.
8. For the current batch of review comments, commit follow-up fixes locally as you go, using one commit per distinct fix unless multiple comments are clearly part of the same change.
9. When the current batch is fully addressed, push once so the PR stays up to date.
10. Continue polling for more review feedback and repeat the verify -> fix -> commit locally -> push once per batch cycle.
11. Stop only when the PR has no outstanding review comments that need action and `coderabbitai` or another reviewer has approved it.

Operating rules:

- Prefer `gh` for PR discovery, creation, review inspection, and comment polling.
- Treat line numbers in review comments as hints only.
- Skip outdated or already-fixed comments with a brief reason instead of forcing extra edits.
- Keep changes minimal and validate targeted behavior when practical before each fix commit.
- If a required fix is genuinely ambiguous or blocked, ask one brief question instead of guessing.
