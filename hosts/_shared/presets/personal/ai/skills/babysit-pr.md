---
description: use when the user asks to monitor, watch, or babysit a PR
---

# Babysit PR Skill

## Monitoring & CI Loop
- Use harness tools to monitor PR activity if available; otherwise, poll for new review comments and CI status checks.
- Only process checks and review comments that are **newer than the latest push**.
- Keep an eye on changes to `main` and rebase as needed to keep the branch fresh.
- Loop continuously until all CI checks pass green and all required approvals are secured.
- Stop immediately if the PR is closed or merged, even with checks or approvals outstanding, and report that terminal state.

## Handling Feedback & Failures
- **Verify every bot finding against the source code** before modifying code.
- Fix genuine bugs and CI failures, distinguishing repository issues from infrastructure flakes.
- Reply with a clear written explanation when dismissing false positives.
- If an overriding pull request makes this PR obsolete, stop monitoring, report to the user, and ask before closing.

## Comment Formatting & Media
- Format comments posted on the maintainer's behalf as follows:
  `<!-- model: <slug> --> responding on behalf of <User>\n\n<reply>`.
- Embed screenshots or uploaded media links when visual evidence helps clarify the fix.

## Scope Constraint
- **Do not allow review feedback to expand the PR beyond the original goal.** Address genuine issues, but strictly prevent scope creep.
