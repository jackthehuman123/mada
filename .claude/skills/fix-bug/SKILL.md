---
name: fix-bug
description: Use when something in the game or tools is broken — reproduce first, then fix.
---

Golden example: `tests/scene.spec.luau` (a failing Lune test that pins the bug).

1. Reproduce. Pure logic: write a failing Lune spec in `tests/`. Engine glue: write a `[playtest]` repro in the spec.
2. Run it and confirm it fails for the reason reported.
3. Fix the smallest thing that makes it pass. No fix without a repro.
4. Run `tools/check.sh`; it must print `OK`.
5. Add the bug to the spec's Feedback log if Catlyn reported it; update `docs/ISSUES.md`.
6. Commit.
