---
name: review-code
description: Two-axis review (Standards + Spec) of changes since a fixed point — repo coding standards plus a Fowler smell baseline, and conformance to the originating issue/PRD/spec. Reports locally by default. Use whenever the user wants to review a branch, a PR, work-in-progress changes, or asks to "review since X". Only when the request explicitly says to post — `--post`, "post to the PR", "post this review to GitHub" — does it publish the findings as a batched pending review via the gh CLI.
argument-hint: '<fixed-point> [--post]'
allowed-tools: AskUserQuestion
---

# Code Review (Two-Axis, Local by Default)

## Overview

Review the diff between `HEAD` and a fixed point along two deliberately separate axes:

- **Standards** — does the code conform to this repo's documented coding standards (plus a fixed smell baseline)?
- **Spec** — does the code faithfully implement the originating issue / PRD / spec?

**The local report is the deliverable.** Steps 1–5 produce it and stop there. Posting to GitHub is opt-in: it happens only when the user's request explicitly asked for it (step 6). When it does happen, it always goes through a **pending review** (batched comments, one notification) and always requires **explicit user approval of the exact content** before anything is published.

## Process

### 1. Pin the fixed point

Whatever the user said is the fixed point — a commit SHA, branch name, tag, `main`, `HEAD~5`, a PR number, etc. If they didn't specify one, ask. If they gave a PR number, the fixed point is the PR's base branch (`gh pr view <N> --json baseRefName`).

Capture once:

```bash
git rev-parse <fixed-point>                 # must resolve — fail here, not later
git diff <fixed-point>...HEAD               # three-dot: compare against merge-base
git log <fixed-point>..HEAD --oneline       # commit list
```

A bad ref or an empty diff should stop the workflow here with a clear message.

### 2. Identify the spec source

Look for the originating spec, in this order:

1. Issue references in the commit messages or PR description (`#123`, `Closes #45`, GitLab `!67`, etc.) — fetch via the workflow in `docs/agents/issue-tracker.md` if present, or `gh issue view` for GitHub issues.
2. A path the user passed as an argument.
3. A PRD/spec file under `docs/`, `specs/`, or `.scratch/` matching the branch name or feature.
4. If nothing is found, ask the user where the spec is. If they say there isn't one, the Spec axis is skipped and the report notes "no spec available".

### 3. Identify the standards sources

Anything in the repo that documents how code should be written, such as `CODING_STANDARDS.md` or `CONTRIBUTING.md`.

On top of whatever the repo documents, the Standards axis always carries the **smell baseline** below — a fixed set of Fowler code smells (_Refactoring_, ch.3) that applies even when a repo documents nothing. Two rules bind it:

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation — and, like any standard here, skip anything tooling already enforces.

Each smell reads *what it is* → *how to fix*; match it against the diff:

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy** — a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps** — the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession** — a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change** — one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

### 4. Run the two axes — sub-agents only for large diffs

Measure the diff first:

```bash
git diff <fixed-point>...HEAD --shortstat
git diff <fixed-point>...HEAD --name-only | wc -l
```

**Large diff** = more than ~500 changed lines (insertions + deletions) **or** more than ~15 files. Use judgement near the boundary; when in doubt, go inline.

**Small/medium diff → inline.** Perform both reviews yourself, sequentially, but keep the axes strictly separate: complete the Standards pass and write its findings down before starting the Spec pass. Don't let one axis's findings rerank or suppress the other's.

**Large diff → parallel sub-agents** (only if an Agent/Task/sub-agent tool is available in the current environment; if not, fall back to inline and note the diff is large). Send a single message with two Agent tool calls using the general-purpose subagent:

**Standards sub-agent prompt** — include:

- The full diff command and commit list.
- The list of standards-source files found in step 3, **plus the smell baseline from step 3 pasted in full** — the sub-agent has no other access to it.
- The brief: "Report — per file/hunk where relevant — (a) every place the diff violates a documented standard: cite the standard (file + the rule); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls — documented-standard breaches can be hard, but baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words."

**Spec sub-agent prompt** — include:

- The diff command and commit list.
- The path or fetched contents of the spec.
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words."

If the spec is missing, skip the Spec axis (inline or sub-agent) and note this in the final report.

**In every mode, record for each finding:** file path, line number(s) in the new version of the file, severity (blocking / judgement call / question), and — where a concrete fix exists — a code suggestion. This structure is what makes posting to GitHub possible later.

### 5. Aggregate the report

Present the two reports under `## Standards` and `## Spec` headings, verbatim or lightly cleaned. Do **not** merge or rerank findings across axes.

End with a one-line summary: total findings per axis, and the worst issue _within each axis_ (if any). Don't pick a single winner across axes — that's the reranking the separation exists to prevent.

### 6. Stop here — unless posting was explicitly requested

**The default is local.** You are done at step 5. Do not ask whether to post, and do not offer to.

Continue to step 7 **only** if the request that invoked this skill explicitly asked to publish — a `--post` argument, or wording like "post to the PR", "post this review to GitHub", "leave these as PR comments". Nothing else counts: not a PR number as the fixed point, not a large pile of findings, not "this is important".

If posting was requested but the changes aren't associated with a GitHub PR, say so and stop at the local report.

If posting was *not* requested, close with a single line noting it's available — "Run again with `--post` to publish these to the PR." — and stop.

### 7. Check gh CLI (only now — posting requires it)

```bash
gh --version
```

**If gh is not installed:** stop immediately — do not attempt `gh api` commands. Tell the user:

```
The GitHub CLI (gh) is required to post the review but is not installed.

Install it from: https://cli.github.com/
- macOS: brew install gh
- Windows: winget install GitHub.cli
- Linux: see https://cli.github.com/ for your distro

After installing, authenticate with:
  gh auth login

Then ask me to post the review again — the analysis above is still valid.
```

The local report already delivered stays valid; only the posting is blocked.

### 8. Derive the event type, then confirm

Derive from the findings — do not ask cold:

| Findings profile | Derived event |
|---|---|
| Any blocking issue (bugs, security, spec requirement missing/wrong, failing tests) | `REQUEST_CHANGES` |
| Only judgement calls / style / non-blocking suggestions | `APPROVE` |
| Only questions or neutral observations | `COMMENT` |

State the derived event and one-line reasoning, and confirm it as part of the approval step below — the user can override it there.

### 9. Show exactly what will be posted, and get explicit approval

**CRITICAL: never post anything before the user has seen the exact content and said yes.**

Map findings to review comments (file + line + body + optional ```suggestion block). Then show:

- Each comment: file, line number, exact body text including any code suggestions
- The derived event type and why
- The overall review message

Then use AskUserQuestion:

```
Question: "Ready to post this review as <EVENT_TYPE>?"
Header: "PR Review"
Options:
  - Yes, post it: Posts the review exactly as shown
  - Change event type: Keep comments, pick a different event
  - No, let me revise: Refine comments before posting
```

Wait for the answer. "The user already approved the review idea" is **not** approval of the content.

### 10. Post via a pending review — always

**ALWAYS use the pending review pattern, even for a single comment, even under time pressure.**

```bash
# Prerequisites
gh pr view <PR_NUMBER> --json commits --jq '.commits[-1].oid'   # commit SHA
gh repo view --json owner,name                                   # usually auto-detected

# Step 1: Create PENDING review (no event field)
gh api repos/:owner/:repo/pulls/<PR_NUMBER>/reviews \
  -X POST \
  -f commit_id="<COMMIT_SHA>" \
  -f 'comments[][path]=path/to/file.ts' \
  -F 'comments[][line]=<LINE_NUMBER>' \
  -f 'comments[][side]=RIGHT' \
  -f 'comments[][body]=Comment text

```suggestion
// suggested code here
```

Additional explanation...' \
  --jq '{id, state}'

# Returns: {"id": <REVIEW_ID>, "state": "PENDING"}

# Step 2: Submit the pending review
gh api repos/:owner/:repo/pulls/<PR_NUMBER>/reviews/<REVIEW_ID>/events \
  -X POST \
  -f event="<EVENT_TYPE>" \
  -f body="Overall review message"
```

Repeat the four `comments[][...]` parameters per comment to batch multiple comments into the one pending review (see Complete Example).

## gh Syntax Reference

### Required parameters

- `commit_id`: latest commit SHA from the PR
- `comments[][path]`: file path relative to repo root
- `comments[][line]`: end line number (use `-F` for numbers)
- `comments[][side]`: `RIGHT` for added/modified lines (most common), `LEFT` for deleted lines
- `comments[][body]`: comment text with optional ```suggestion block

### Optional parameters

- `comments[][start_line]`: for multi-line code suggestions (use `-F`)
- `event`: omit for PENDING, or `COMMENT`/`APPROVE`/`REQUEST_CHANGES` on submit

### Syntax rules

✅ **DO:**
- Use single quotes around parameters with `[]`: `'comments[][path]'`
- Use `-f` for string values, `-F` for numeric values (line numbers)
- Use triple backticks with the `suggestion` identifier for code suggestions

❌ **DON'T:**
- Use double quotes around `comments[][]` parameters
- Mix up `-f` and `-F`
- Forget to get the commit SHA first

### Code suggestions

Suggestions replace the entire line or line range — make the suggested code complete and correct:

```bash
-f 'comments[][body]=Your comment explaining the issue

```suggestion
const fixed = "like this";
```

Additional context after the suggestion.'
```

**Nested code blocks** (suggesting changes to markdown containing triple backticks): wrap the suggestion in 4 backticks or tildes:

`````markdown
````suggestion
```javascript
const example = "value";
```
````
`````

Or:

```markdown
~~~suggestion
```javascript
const example = "value";
```
~~~
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Posting immediately under time pressure | Still create pending review first — can submit immediately after |
| "Only one comment so no need for pending" | Use pending anyway — consistent workflow, allows adding more |
| Posting because the findings seem important, without being asked | Local is the default — publish only on an explicit `--post`/"post to the PR" |
| Asking "shall I post this?" when they didn't ask | Don't offer. Note `--post` exists in one line and stop |
| Merging Standards and Spec findings into one ranked list | Keep the axes separate end to end |
| Forgetting single quotes around `comments[][]` | Always quote: `'comments[][path]'` |
| Not getting the commit SHA | `gh pr view <N> --json commits --jq '.commits[-1].oid'` |
| Announcing an event type without deriving it from findings | Derive from the table, then confirm with the user |

## Red Flags — You're About to Violate the Pattern

Stop if you're thinking:

- "User said ASAP so I'll skip the pending review"
- "Only one comment so I'll post directly"
- "User already approved the review idea, so I'll skip showing the content"
- "I'll post it and then tell them what I posted"
- "They gave me a PR number, so they obviously want it posted"
- "These findings are too important to leave in a local report"
- "gh is probably installed, no need to check"
- "The diff is big but I'll just review it inline anyway without noting it" (fine to go inline when no sub-agent tool exists — but say so)
- "Standards found something worse, so I'll bury the Spec findings"

All of these mean: **STOP.** Publish only on an explicit request, then check gh, show exact content, get explicit approval, and use a pending review.

## Why This Shape

**Two separate axes** — a change can pass one and fail the other. Code that follows every standard but implements the wrong thing: Standards pass, Spec fail. Code that does exactly what the issue asked but breaks conventions: Spec pass, Standards fail. Reporting them separately stops one axis from masking the other.

**Pending reviews** — same effort (2 API calls vs 1) but: all feedback lands as one notification, you can add comments as you find more issues, and you can re-read your own comments before they go public.

**Explicit approval** — review comments are public and permanent; suggestions might be wrong; tone might need adjustment. The user must see the exact content, not a summary of intent.

**Local by default** — a review you asked for is information; a review posted to a PR is a message to your colleagues. The second is outward-facing and hard to retract, so it takes a deliberate `--post`, not a prompt you might wave through.
