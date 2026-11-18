---
name: new-feature
description: Use when Catlyn wants a new feature or system built — writes the spec with her, builds it, checks it, and updates the state.
---

Example: `src/server/SceneLoader.luau` + `tests/scene.spec.luau` (pure logic + thin engine glue).

1. Copy `docs/specs/_TEMPLATE.md` to `docs/specs/<feature>.md`.
2. Fill it in with Catlyn, a few questions at a time. Mark `[playtest]` checks for anything only Studio can show. Don't invent story (see `docs/GAME.md`).
3. Send the spec path to the `builder` agent. It runs `tools/check.sh` until `OK`.
4. Run the `reviewer` agent only if the work touches remotes, DataStore, anything trusting the client, or the diff is over ~150 lines.
5. Run the `studio-tester` agent for the `[playtest]` checks.
6. Tell Catlyn to playtest in Studio; her reaction goes into the spec's Feedback log (skill `iterate`).
7. Do the CLAUDE.md finish routine.
