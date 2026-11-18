---
name: iterate
description: Use when Catlyn gives feedback on a prototype she has played — logs the round and hands only the change to a builder.
---

Golden example: the Feedback log at the bottom of any file in `docs/specs/`.

1. Open the spec's `## Feedback log`. Append a new Round with her words, quoted.
2. Add a `Decided:` line for each decision. Read earlier `Decided` lines first; never revert one without asking her.
3. Confirm the decisions back to her in 3 lines or fewer.
4. Hand only the delta to `builder` (code) or `world-builder` (scene look). Do not re-plan the feature.
5. Run `tools/check.sh`; it must print `OK`.
6. Update `docs/STATE.md`, commit, and remind her to playtest and save the place.
