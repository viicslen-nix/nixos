Act as a professional engineering assistant. Generate a daily work log summary from my git commits made today, written for a **non-technical audience** and formatted to paste straight into Discord.

## 1. Retrieve commits (multi-source)

Today means the `America/New_York` day. Run these in parallel — no single source is complete:

- **Local repo, all branches:** `git log --all --since="<today> 00:00:00 -0400" --until="<tomorrow> 00:00:00 -0400" --author=<my gh login> --no-merges --pretty=format:'%h|%ad|%s' --date=format-local:'%H:%M'`
- **Both orgs on GitHub:** for each of `FmTod` and `FmTod2`, `gh search commits --author=<login> --owner=<org> --author-date=<today> --limit 100 --json repository,commit --jq '.[] | "\(.repository.name) :: \(.commit.author.date) :: \(.commit.message | split("\n")[0])"'`
- **Submodules:** `git submodule foreach --quiet 'git log --all --since=… --author=… --no-merges --oneline'`

Resolve my identity first (`git config user.name`, `git config user.email`, `gh api user --jq .login`) — do not assume it.

The local log and the GitHub search each miss things the other catches. `gh search` only indexes pushed, indexed commits, so recent local work is invisible to it; the local clone misses work done in other repos. **Merge both sets and dedupe by subject.** If commits exist locally but not on GitHub, say so in a footnote with the earliest such timestamp ("commits from 2:57pm onward are still local and not yet pushed").

## 2. Filter noise

Exclude merge commits, bot commits (Dependabot et al.), empty commits, harness checkpoint commits (author `T3 Code`, subjects like `t3 checkpoint ref=…`), and commits authored by anyone other than me.

**Dedupe squashed PRs:** a squashed commit `subject (#1234)` on master and the branch commits behind it are the same work. Report it once and carry the PR number.

## 3. Read the *why*, don't guess it

For every substantive commit, read the full message body — `git log -1 --pretty=format:'%s%n%n%b' <sha>` — batched, not one at a time. The body is where the actual reason lives; the subject alone is rarely enough to explain impact. Use `git show --stat` when the body is thin.

Never invent cause, scale, or user impact. If a commit body reports a measured figure, you may quote it and attribute it ("measured on the production replica"); never state a number you did not read or measure yourself.

## 4. Write it in plain English

The reader is not an engineer. For each item:

- **Lead with the user-visible effect, in bold**, then explain the cause in one or two plain sentences.
- Say what was broken and who it affected, not which class or method changed. "Non-US sellers weren't getting their eBay ad fees synced at all" beats "send marketplace id header on Finances requests".
- Drop identifiers a non-engineer can't use — no file paths, class names, or method names. Keep product names, commands a person might actually run, PR numbers, and real figures.
- Expand jargon on first use, or replace it.
- Be genuinely detailed — several sentences per meaningful change is right. A one-line restatement of the commit subject is not.
- Keep routine work (release merges, dependency bumps) to a single terse line.

## 5. Group hierarchically

`#` day title → `##` repository (`owner/name` in backticks, with commit count) → `###` theme or feature area with a leading emoji. Treat all repos equally; never group by organization. Order themes by significance, not by timestamp.

## 6. Format for Discord

- **Hard limit 2000 characters per message.** Split into as many messages as needed and **verify each with `wc -m`** — do not estimate.
- Present each message inside its own fenced block so it can be copied cleanly, labelled `## Message N — <count> chars`.
- Discord markdown only: `#`/`##`/`###` headers, `-` bullets, `**bold**`, `` `inline code` ``, and `-#` for small subtext. **No tables, no blockquotes** — Discord does not render them.
- Split at a natural section boundary where you can. Do not repeat the repo header or add a `(cont.)` marker on a continuation — the messages read as one continuous post in the channel.
- Close the final message with a `-#` subtext line naming what was excluded and any unpushed-work caveat.

**Fallback:** If no commits were found today across any source, reply only: "No commits found for today."
