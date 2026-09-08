# CONTEXT

Local deltas applied to upstream skills by `patchSkill`, one file per skill.
Each is a list of `{from; to;}` spans rewritten into the upstream `SKILL.md`.

## grilling.nix

A local delta on `github:mattpocock/skills` — `skills/productivity/grilling`.

Upstream has the agent print numbered questions as prose and wait for the user
to type answers back. Every harness we run it in has an interactive question
tool instead, so the round goes through that and the prose block is kept as the
documented fallback.

The `from` anchors are plain ASCII spans that have survived every upstream
reword so far. `patchSkill` asserts they still exist, so a reword breaks the
build rather than silently reverting grilling to vanilla. Paragraphs in `to`
are single unwrapped lines, to match the surrounding upstream prose.
