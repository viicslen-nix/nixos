---
name: autofix
description: Auto-fix CodeRabbit review comments - get CodeRabbit review comments from GitHub and fix them interactively or in batch.
version: 0.1.0
---

# CodeRabbit Autofix

Fetch CodeRabbit review comments for your current branch's PR and fix them interactively or in batch.

## Prerequisites

### Required tools

- `gh` (GitHub CLI)
- `git`

Verify:

```bash
gh auth status
```

### Required state

- GitHub repository
- Current branch has an open PR
- PR reviewed by CodeRabbit bot (`coderabbitai`, `coderabbit[bot]`, `coderabbitai[bot]`)

## Workflow

1. Load repository instructions (`AGENTS.md`) if present.
2. Check `git status` and unpushed commits.
3. Find open PR for current branch.
4. Fetch unresolved CodeRabbit threads.
5. Parse and display issues in original order.
6. Ask user whether to review each issue, auto-fix all, or cancel.
7. Apply fixes from CodeRabbit agent prompts.
8. Create one consolidated commit.
9. Optionally run build/lint/test checks.
10. Optionally push changes.
11. Post summary comment to PR.

## Commands

Find PR:

```bash
gh pr list --head $(git branch --show-current) --state open --json number,title
```

Fetch unresolved threads (GraphQL):

```bash
gh api graphql \
  -F owner='{owner}' \
  -F repo='{repo}' \
  -F pr=<pr-number> \
  -f query='query($owner:String!, $repo:String!, $pr:Int!) {
    repository(owner:$owner, name:$repo) {
      pullRequest(number:$pr) {
        reviewThreads(first:100) {
          nodes {
            isResolved
            comments(first:1) {
              nodes {
                databaseId
                body
                author { login }
              }
            }
          }
        }
      }
    }
  }'
```

Create consolidated commit:

```bash
git add <all-changed-files>
git commit -m "fix: apply CodeRabbit auto-fixes"
```

Post PR summary comment:

```bash
gh pr comment <pr-number> --body "$(cat <<'EOF'
## Fixes Applied Successfully

Fixed <file-count> file(s) based on <issue-count> unresolved review comment(s).

**Files modified:**
- `path/to/file-a.ts`
- `path/to/file-b.ts`

**Commit:** `<commit-sha>`

The latest autofix changes are on the `<branch-name>` branch.

EOF
)"
```

## Key Notes

- Follow the CodeRabbit "Prompt for AI Agents" literally when available
- Preserve issue titles and ordering from CodeRabbit output
- Avoid per-issue PR replies; post one summary comment
