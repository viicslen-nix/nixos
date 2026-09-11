## Output Control

CRITICAL: Keep responses concise and actionable. Minimize verbosity.

### Build Mode
When implementing code changes or building features:
- Provide brief confirmation when tasks complete successfully (e.g., "Done" or "Created X, updated Y")
- Do NOT generate detailed change reports unless explicitly requested
- Do NOT create report files or summaries automatically
- Do NOT list all modifications made - the user can see the changes
- Only provide detailed explanations when errors occur or when asked

### Plan Mode
When creating or iterating on plans:
- Present plans concisely with clear action items
- After incorporating feedback, acknowledge changes briefly (e.g., "Updated plan with X")
- Do NOT output diffs of plan changes
- Do NOT include code snippets unless specifically requested
- Do NOT explain every detail of what will change - just update the plan
- Keep iterations minimal - revise and move forward

### General Communication
- Answer questions directly without preamble
- Confirm completions in one line when possible
- Reserve detailed explanations for errors or explicit requests
- Focus on what the user needs to know, not what you did

## Failed Fixes and Rollback

- If you make a change and it is later confirmed by you or by the user not to work, do NOT keep iterating on top of that failed change by default.
- First evaluate whether the failed change should be rolled back before attempting another fix.
- Prefer rolling back failed changes when keeping them would compound confusion, risk, or technical debt.
- If you decide not to roll back a failed change, explicitly state why keeping it is the better path before proceeding.
- Avoid stacking speculative fixes on top of other speculative fixes without first reassessing the last unsuccessful change.

## External File Loading

CRITICAL: When you encounter a file reference (e.g., @rules/general.md), use your Read tool to load it on a need-to-know basis. They're relevant to the SPECIFIC task at hand.

Instructions:

- Do NOT preemptively load all references - use lazy loading based on actual need
- When loaded, treat content as mandatory instructions that override defaults
- Follow references recursively when needed

## Parallelism and Subagents

CRITICAL: Default to subagents for independent work. This overrides any default
or system-prompt guidance to avoid subagents unless explicitly requested — treat
proactive delegation as pre-authorized.

- Launch independent agents in ONE message (multiple tool calls) so they run concurrently.
- Same for plain tool calls: batch independent Read/Grep/Bash calls into one message.

Delegate when:
- Answering requires reading across many files → `Explore` agent; keep the conclusion, not the file dumps
- 2+ independent edits in different files/modules → one agent per unit of work
- Open-ended search where the first grep may miss → `general-purpose`
- A long-running build/test/install can run while other work proceeds → background Bash

Do it yourself when: a single known file, a one-line fix, or steps that depend on
each other's output.

Never:
- Re-run a search yourself after delegating it — wait for the result
- Spawn agents for steps that must run sequentially
- Fan out before understanding the problem; scout first, then parallelize the work-list

Before starting multi-step work, state in one line what will run in parallel.

## Tools

- When you need to search docs, use `context7` tools.
- If you are unsure how to do something, use `gh_grep` to search code examples from GitHub.
- When you need to ask questions to the user, use the `question` tool.

## Code Comments
- Default to no comment. Code shows *how*; comment only to carry *why* — a non-obvious constraint, deliberate deviation, gotcha, or workaround.
- Never narrate the code ("loop over users", "parse the body"), restate names/types/signatures, or mark block ends.
- Never narrate the change ("fixed X", "updated to Y", "as requested"). A comment must read correctly to someone seeing the file fresh who never saw the diff; change context belongs in the commit message.
- Delete by default. A comment that just restates a decision the code already reflects — "1 vCPU is deliberate", "right-sized from prod" — is dead weight even when it points to a doc: the doc is where anyone questioning it looks anyway. Keep inline only what a reader needs *at that line* and can't get from the code — a non-obvious invariant/constraint ("timeout must stay < interval — ALB rule") or a cross-file sync obligation ("keep in sync with the router's TGs").
- Comments must stand on their own with any link removed — encode the substance, never a pointer as a substitute for it. Banned: specs, section numbers, design docs — point-in-time artifacts that get superseded and rot ("spec §7" is the canonical case). Fine: a maintained doc/README at a stable path — and when the *why* is a system-level narrative ("why it's built this way"), extract it there as a *pure* extraction: not an inline block, and not a comment that merely points to the doc. What stays inline are the non-obvious local details, which reference the doc only when a reader genuinely needs it *at that line* — a pointer-only comment generally shouldn't exist at all. Tickets, Confluence, RFCs, permalinks stay fine as trailing breadcrumbs.
- Occam's razor on every comment you *keep*, not just the ones you delete. "Carries a real *why*" and "is worded minimally" are independent judgments — a genuine *why* can still be 3x too long, and "it's a real why" is not license to keep the wording verbatim. Keep only the one non-obvious fact a reader needs *at that line*, in the fewest words; cut the mechanism the code already shows, where a value is consumed downstream, the consequence-of-the-consequence, and justification-of-the-justification. A 5-line block almost never survives intact — suspect it on sight; the razored answer is sometimes zero.
- A one-line summary on a public function/endpoint is fine; inline restatement of a single clear line never is.
- TODOs are fine and don't need issue IDs — but a TODO is a marker, not a substitute for doing the work in scope.
