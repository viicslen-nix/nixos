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
