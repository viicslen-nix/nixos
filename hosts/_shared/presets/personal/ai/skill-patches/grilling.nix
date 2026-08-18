# Local delta on github:mattpocock/skills — skills/productivity/grilling.
#
# Upstream has the agent print numbered questions as prose and wait for the
# user to type answers back. Every harness we run it in has an interactive
# question tool instead, so put the round through that and keep the prose block
# as the documented fallback.
#
# Anchors are plain ASCII spans that have survived every upstream reword so
# far. `patchSkill` asserts they still exist, so a reword breaks the build
# rather than silently reverting grilling to vanilla. Paragraphs are single
# unwrapped lines to match the surrounding upstream prose.
[
  {
    from = "Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.";
    to = ''
      Ask the whole frontier in one round, through the harness's interactive question tool where one exists (in Claude Code: `AskUserQuestion`), rather than as prose the user has to answer by hand. That tool takes a bounded number of questions per call and each call blocks until answered, so a wide frontier is simply several calls back to back — never a reason to hold part of the frontier back for a later round.

      Per question: a short `header`, the decision itself as the `question`, and 2-4 concrete `options`. Your recommended answer goes **first**, with `(Recommended)` appended to its label, and each option's `description` says what picking it commits you to. Use `multiSelect` when the choices genuinely compose rather than exclude. An open-ended decision still belongs in the tool: enumerate the answers you would expect, and let the user's free-text "Other" override you.

      Then wait for the user's answers before the next round.'';
  }
  {
    from = "Each question should be formatted like so:";
    to = "Where no such tool exists, fall back to asking in prose, formatted like so:";
  }
]
