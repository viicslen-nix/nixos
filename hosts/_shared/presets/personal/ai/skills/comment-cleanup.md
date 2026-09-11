---
name: comment-cleanup
description: Clean up code comments — remove AI-generated over-commenting, narration, and noise while preserving comments that carry real context. Use whenever the user asks to clean, tidy, prune, fix, audit, or review comments in code, mentions "too many comments", "verbose comments", "comment pass", "de-AI the comments", or asks to apply comment guidelines to a file, diff, or PR. Also use after an implementation when the user asks to tidy up before committing.
---

# Comment Cleanup

A comment-only editing pass. Walk every comment in the target files, keep the few
that carry context the code cannot, delete or rewrite the rest.

## Scope — read this first

**Edit comments only. Never change code in this pass.** No renames, no
extractions, no logic changes, no "improvements" — even when a comment exists
only because the code is unclear. In that case the comment may survive the pass
(it is doing real work, badly) and the situation goes in the summary as a flag
for the user to act on. The user may separately ask for refactors; that is a
different task.

Whitespace left behind by deleted comments should be tidied (no orphaned blank
lines), but the code itself must be byte-identical.

## The core principle

Code already shows **how**. A comment earns its place only by carrying **why**
— context the code cannot: a non-obvious constraint, a deliberate deviation, a
gotcha, a workaround, the reason a tempting simpler version is wrong. When in
doubt about a *why* comment, keep it; when in doubt about a *how* comment,
delete it. Wrongly deleting a warning that does real work costs far more than leaving
one mediocre comment behind.

## The pass — apply to every comment, in order

**1. Is it narration?** Restates the code, describes the steps ("loop over the
accounts", "parse the request body"), restates names/types/signatures, or marks
block ends (`} // end if`). → **Delete.** This is the bulk of agent-generated
comment noise. The code below it was fine all along; do not touch it.

**2. Is it change narration?** Addressed to the reviewer of a diff rather than
a reader of the file: "updated to use the v2 client", "removed the old
fallback", "added per feedback", "fixed the off-by-one". → **Delete.** Test:
would the sentence make sense to someone reading the file fresh, a year from
now, who never saw any PR? If not, it belongs in a commit message, and the
commit already happened.

**3. Does it point at a moving target?** "See spec section 3", "per the
requirements doc", "see the design doc". → **Delete** if the annotated point
didn't need a comment at all (spec compliance itself never does), or **rewrite**
to encode the substance of the requirement directly. What counts as durable vs
ephemeral:

- **Durable (allowed, as breadcrumbs):** issue/ticket IDs (`WAGE-1234`),
  Confluence pages, RFCs and standards, permalinked sources, issue-tracker
  links — and a **maintained repo doc/README at a stable path** (e.g.
  `cdk/PREVIEW_INFRA.md`), which lives and updates alongside the code. These
  have stable addresses. A README is *not* a rotting spec — don't lump the two.
- **Ephemeral (rewrite or delete):** "the spec", "the requirements", a design
  doc (a point-in-time artifact that gets superseded), and **any section number
  of any document** — "spec §7", "section 4.2" — the canonical ephemeral form. A
  section number is never durable, no matter what document it indexes into.

This rule applies **inside docstrings exactly as in `#` comments** — a
"per spec §11" buried in a module docstring is the same defect.

Even a durable reference is a *breadcrumb*, never the explanation itself
— the address survives, but the content behind it can change. The comment must
stand on its own with the link removed:

```python
# Bad:  per requirements doc section 3.2
# Bad:  see WAGE-1234
# Good: Bacs requires 3 *clear working days* between notice and collection,
#       deliberately not "+3 calendar days" (WAGE-1234).
```

**4. Is it a *why* that's bloated or misplaced?** For comments that do carry
real rationale, in sequence:

- *Does the rationale belong in a doc, not here?* System-level "why it's built
  this way" narrative — an architecture decision, a benchmark result, a
  lifecycle overview — reads better in a maintained doc/README than in a long
  inline block. If a durable doc **already** carries it → delete the inline copy;
  do **not** leave a signpost. A comment that only restates a decision the code
  already reflects ("right-sized from prod", "1 vCPU is deliberate") is dead
  weight *even pointed at the doc* — the doc is the first place anyone
  questioning the value looks. If no such doc exists yet, keep the comment but
  **flag it** as extraction-worthy (writing the doc is out of scope for a
  comment-only pass). Extraction is *pure*: once the narrative lives in the doc,
  what survives inline is only the local invariant a reader needs *at that
  line* — a non-obvious constraint ("timeout < interval — ALB rule") or a
  cross-file sync obligation ("keep in sync with X") — not a pointer to the doc.
  A comment that is *nothing but* a pointer ("see PREVIEW_INFRA.md") generally
  shouldn't exist; inline may reference the doc only when a reader genuinely
  needs it there, and even then the substance, not the pointer, is the point.
- *Is all of it necessary?* Trim throat-clearing, restated context the reader
  already has, and anything the code itself shows. Keep every part that a
  future maintainer would need to avoid breaking or "simplifying" the code.
- *Does it belong in one block?* A long header block covering several distinct
  points often serves better broken up, with each short comment placed adjacent
  to the line it governs. Proximity is what keeps comments true: a comment next
  to its line gets updated when the line changes; a header block three screens
  up does not.
- *Is the remaining length earned?* Some rationale is irreducibly multi-part
  (a workaround plus the bug it works around plus the deprecation plan).
  Length alone is not a defect — unearned length is. Never shorten a comment
  at the cost of the information in it.

The trap this rule exists to catch: **"carries a real *why*" and "is worded
minimally" are independent judgments.** A comment can carry genuine rationale
*and* still be three times too long. Passing the first test does not exempt it
from the second — do not let "it's a real why" become a verdict to keep the
wording verbatim. Apply Occam's razor to *every surviving comment*: keep the
single non-obvious fact a reader needs at that line, in the fewest words, and
cut everything else — the mechanism the code already shows, where a value is
consumed downstream, the consequence-of-the-consequence, restated names/types,
and justification of the justification. The razor's answer is sometimes zero:
delete. A five-line block almost never survives intact; suspect it on sight.

```python
# Before (5 lines): First key/value of every emitted line. Gives every event
#   the stable prefix {"stream":"bi.telemetry" — filterable in CloudWatch Logs
#   Insights (filter stream = "bi.telemetry") and usable as a subscription-
#   filter pattern ({ $.stream = "bi.telemetry" }) when the Snowpipe landing
#   (DT-2485) is built.
# After (1 line):   Stable first-key prefix ({"stream":"bi.telemetry") for
#   log filtering.
```

**5. Is it stale?** Describes code that no longer exists or behavior that has
changed. → **Delete** (or correct it, if the underlying point still holds and
is worth keeping). A wrong comment is worse than no comment.

**6. None of the above?** It explains a non-obvious constraint, a surprising
but essential line, a contract the signature can't show (units, ranges,
side effects, failure modes), an edge case, or the source of a copied
algorithm. → **Keep.** Do not reword comments that are already fine — churn on
good comments is itself noise in the diff. But "already fine" means *already
minimal*, not merely correct: a correct-but-bloated comment is a rule-4 target,
not a keep. Reserve the no-churn rule for comments that are already tight.

Three keep categories that are easy to misread as deletable — they are not:

- **Cross-file consistency pointers** — "mirrors the Overview page", "same
  logic as kpi1", "keep in sync with X". The *link itself* is the why: it
  prevents two copies drifting apart. Deleting it deletes the only thing
  stopping the next editor from changing one side.
- **Data-literal semantics** — comments giving the meaning, order, or units of
  a literal (`# (width, height) in portrait` on a tuple table, `# pence, not
  pounds`). The literal cannot show its own convention.
- **Presentation/format contracts** — "£ with full thousands, as the
  dashboard". These pin output format to an external expectation.

**Structural section banners** (`# --- Name ---` dividers) are navigation, not
narration — they don't restate any line of code. Treat them as house style and
keep them unless the user asks for their removal. If a banner carries substance
beyond its label, that substance is protected like any other *why*.

## TODOs

Keep TODO/FIXME comments. They do not need issue IDs. Two exceptions:

- A TODO describing work that has visibly been done → stale, delete (rule 5).
- A TODO that is deferral disguised as a marker — e.g. `# TODO: handle errors`
  on a path that plausibly should already handle them → keep it, but flag it
  in the summary; deleting it would hide real incompleteness.

## Docstrings

All six rules apply inside docstrings, including rule 3's reference rules. A
docstring that only re-emits the function name and parameter types is
narration → delete or reduce. One that documents the contract the signature
can't show (units, valid ranges, side effects, what happens on failure,
invariants, what has *already* been done to the inputs) → keep. Condensing a
docstring to a one-liner is valid only when nothing beyond signature
restatement is lost — a docstring that explains preconditions, boundary
ownership, or cross-module behavior is contract, and trimming it to a summary
line deletes the contract. A brief one-line summary on a public function,
endpoint, or API surface is legitimate even when short — other teams consume
those without reading the body. Inline restatement of a single clear line is
not legitimate anywhere.

## Output

After editing, report:

1. **Counts** — comments deleted / rewritten / kept, per file.
2. **Flags** — anything the pass could not fix within scope:
   - comments compensating for genuinely unclear code (candidate refactors)
   - deferral TODOs (possible unfinished work)
   - comments whose correctness couldn't be verified (kept conservatively)
3. **Judgment calls** — any borderline keep/delete decisions, one line each,
   so the user can overrule.

Keep the report brief. Do not list every deleted narration comment — they are
the point of the pass, not news.

## Worked examples

**Delete — narration on clean code. Remove every comment; the code is untouched:**

```python
def login():
    # Parse the JSON body of the request into a dict
    info = json.loads(request.data)
    # Read the username key using .get(), which returns None if absent,
    # avoiding a KeyError
    username = info.get("username")
    # Query the User collection and take the first match or None
    user = User.objects(name=username, password=password).first()
```

**Rewrite — block broken up and trimmed, substance kept, placed at point of use:**

```python
# Before: one header block
# This function handles rounding. Note that Stripe rounds half-to-even while
# our ledger rounds half-up, which historically caused reconciliation breaks.
# Also note the amounts must be converted to pence before any arithmetic.
# Finally the result is compared against the original to detect drift.

# After: two adjacent comments, narration dropped
amount_pence = to_pence(amount_gbp)  # convert before arithmetic: float GBP drifts
...
# Stripe rounds half-to-even, ledger rounds half-up — integer pence or you
# get 1p reconciliation breaks (FIN-2231)
rounded = round_half_up(amount_pence)
```

**Keep — surprising but essential, exactly the comment that must survive:**

```python
# JSONTokener.nextValue() may return a value that equals() null —
# both checks are required, do not simplify
if value is None or value == NULL_SENTINEL:
    return None
```
