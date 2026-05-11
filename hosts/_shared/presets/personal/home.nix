{
  modules.programs.ai = {
    enable = true;
    mempalace.enable = true;
    mcps = {
      context7.url = "https://mcp.context7.com/mcp";
      gh_grep.url = "https://mcp.grep.app";
      linear.url = "https://mcp.linear.app/mcp";
      google_stitch.url = "https://stitch.googleapis.com/mcp";
    };
    commands = {
      verify = ''
        Verify each finding against current code. Fix only still-valid issues, skip the
        rest with a brief reason, keep changes minimal, and validate.
      '';
      commit = ''
        Separate the changes or fixes into logical groups and commit them.
        If a list of findings were provided then use that list to create the commits
      '';
      reflect = ''
        Critically review our entire session to identify patterns in our workflow. Determine if we should update the 'Permanent Guidelines' or the 'Skill Library' based on today's work.

        1. Guidelines: Did I have to repeat any preferences (e.g., error handling, naming conventions, library choices)?
        2. Skills: Did we solve a complex problem or configure a specific integration that would be faster if documented as a reusable 'Skill'?

        If changes are necessary, propose specific, concise snippets. If the current workflow is optimal, explain why 'doing nothing' is the best choice.
      '';
    };
    context = ''
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

      ## Tools

      - When you need to search docs, use `context7` tools.
      - If you are unsure how to do something, use `gh_grep` to search code examples from GitHub.
      - When you need to ask questions to the user, use the `question` tool.
    '';
  };
}
