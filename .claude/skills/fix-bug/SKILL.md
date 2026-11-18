---
name: fix-bug
description: Use when something in the game or tools is broken — reproduce first, then fix.
---

Example: `tests/scene.spec.luau` (a failing Lune test that pins the bug).

1. Reproduce. Pure logic: write a failing Lune spec in `tests/`. Engine glue: write a `[playtest]` repro in the feature's spec.
2. Run it (`lune run tests/run`) and confirm it fails for the reason reported.
3. Send the repro to the `builder` agent: fix the smallest thing that makes it pass. It runs `tools/check.sh`. No fix without a repro.
4. For a `[playtest]` repro, run the `studio-tester` agent on it.
5. If Catlyn reported it, add it to the spec's Feedback log.
6. Do the CLAUDE.md finish routine.
