---
description: use when the user asks to file, open, or create a PR
---

# File PR Skill

## Pre-Filing Checks
- Check whether a pull request for this branch already exists before creating a new one.
- Review the diff locally against `origin/main` to verify its contents match the original goal.

## PR Creation & Workflow
- **Do not open draft pull requests.** Open real PRs so automated review bots are triggered.
- If the user also requests to monitor or watch the pull request, continue directly with the **babysit-pr** skill.

## Title Conventions
- Write concise, human-readable titles that explain **why** the changes matter, following repository conventions.
- **Bad Title Example:** `PF server negotiate per message deflate on the websocket`.
- **Good Title Example:** `PF server cut websocket frame size by 70% with gzipping`.

## Description Formatting
- Open the description with a simple explanation of the core problem based on the user's prompt, followed by a brief overview of the solution.
- **Do not lead with an implementation inventory** or a list of file changes.
  - **Bad Description Example:** `removed implicit workspace carryover from every new thread entry point...`.
  - **Good Description Example:** `my new work tree default was ignored when starting new threads on existing work trees...`.
- Include a blurb at the end of the PR description specifying the AI model and harness used to make the changes.
