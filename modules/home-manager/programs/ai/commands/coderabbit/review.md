---
description: Run CodeRabbit AI code review on your changes.
argument-hint: '[type] [--base <branch>]'
allowed-tools: Bash(coderabbit:*), Bash(cr:*), Bash(git:*)
---

# CodeRabbit Code Review

Run an AI-powered code review using CodeRabbit.

## Context

- Current directory: !`pwd`
- Git repo: !`git rev-parse --is-inside-work-tree 2>/dev/null && echo "Yes" || echo "No"`
- Branch: !`git branch --show-current 2>/dev/null || echo "detached HEAD"`
- Has changes: !`git status --porcelain 2>/dev/null | head -1 | grep -q . && echo "Yes" || echo "No"`

## Instructions

Review code based on: **$ARGUMENTS**

### Prerequisites Check

Skip these checks if you already verified them earlier in this session.

Otherwise, run:

```bash
coderabbit --version 2>/dev/null && coderabbit auth status 2>&1 | head -3
```

If CLI is not found, tell the user:

> CodeRabbit CLI is not installed. Run in your terminal:
>
> ```bash
> curl -fsSL https://cli.coderabbit.ai/install.sh | sh
> ```
>
> Then restart your shell and try again.

If not logged in, tell the user:

> You need to authenticate. Run in your terminal:
>
> ```bash
> coderabbit auth login
> ```
>
> Then try again.

### Run Review

Once prerequisites are met:

```bash
coderabbit review --agent -t <type>
```

Where `<type>` from `$ARGUMENTS`:

- `all` (default) - all changes
- `committed` - committed changes only
- `uncommitted` - uncommitted changes only

Add `--base <branch>` if specified.

### Present Results

Group findings by severity:

1. Critical - security and bugs
2. Suggestions - improvements
3. Positive - what is good

Offer to apply fixes if `codegenInstructions` are present.
