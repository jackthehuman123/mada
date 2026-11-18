---
name: iterate
description: Use when Catlyn gives feedback on a prototype she has played — logs the round and hands only the change to a builder.
---

Example: the Feedback log at the bottom of `docs/specs/scene-village.md`.

1. Open the spec's `## Feedback log` (scenes: `docs/specs/scene-<name>.md`). Append a new Round with her words, quoted.
2. Add a `Decided:` line for each decision. Read earlier `Decided` lines first; never revert one without asking her.
3. Confirm the decisions back to her in 3 lines or fewer.
4. Hand only the delta to `builder` (code) or `world-builder` (scene look); they run `tools/check.sh`. Do not re-plan the feature.
5. Tell her to playtest.
6. Do the CLAUDE.md finish routine.
