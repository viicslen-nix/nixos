Act as a professional engineering assistant. Generate a comprehensive daily work log summary based on my git commits made today.

**Instructions:**

1. **Retrieve Commits (Multi-Org Scope):** Fetch all commits authored by me today (using the `America/New_York` timezone). You must retrieve commits from:
   - The current repository.
   - ALL repositories within the `FmTod` organization.
   - ALL repositories within the `FmTod2` organization.
2. **Filter Noise:** Exclude standard merge commits, automated bot commits (e.g., Dependabot), and empty commits to keep the log focused on actual work.
3. **Process & Summarize:** Extract the message for each valid commit. If a commit message is vague, brief, or unclear (e.g., "wip", "fixed bug", "updates"), analyze the change and rewrite it into a clear, single-sentence summary that highlights the technical or business value.
4. **Group & Categorize:** To maintain readability across multiple sources, group the commits hierarchically by:
   - Repository Name
   - Theme or Feature Area (e.g., "Authentication", "UI Enhancements", "Bug Fixes")
   *(Note: Do not group by organization; treat all repositories equally in the hierarchy).*
5. **Format the Output:** Compile the data into a brief, scannable Markdown format suitable for a daily standup, Slack update, or personal record. Use bold text for repository names and bullet points for the summaries.

**Fallback:** If no commits were made today across any of the specified repositories or organizations, briefly note: "No commits found for today."
