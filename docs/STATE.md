# State

History is in `docs/PROGRESS.md`; open work in `docs/ISSUES.md`. Keep this file ≤ 40 lines.

## Milestone
Playtest build. Everything is merged on `main`; the factory-2 branch (`factory-2`) is reworking the agent setup and the scene pipeline.

## Done
- M0–M6: toolchain, graybox village, clues and camcorder, Night 1, mystery content, Sen and rescue, endings and midnight (a full run is playable).
- M7 partly: audio pass done, graybox dressed in code; model art pass not done.
- M8 partly: analytics summary, menu and teams; the Stay ending was cut; the Quiet Man is left out until after the first playtest.
- Factory 2.0 so far (Tasks 1–5): `tools/check.sh`, Lune runner, post-edit hook and permissions, scene data and validators, `SceneLoader`, `tools/extract-prefabs.luau`.
- Task 6: lean docs (this file, `CLAUDE.md`, `GAME.md`, `MODULES.md`, `CONVENTIONS.md`, `REVIEW_CHECKLIST.md`, `specs/_TEMPLATE.md`).

## Next
- Factory 2.0 Tasks 7–9: subagents with fixed models, skills, test run and comparison (`docs/superpowers/plans/2026-11-17-roblox-factory-2.md`).
- A real playtest with 2–4 people; the art pass in the shared place.

## Known issues
- `village/layout.luau` is empty: no prefabs placed until the workshop is extracted into `assets/prefabs/`.
- `luau-lsp` doesn't typecheck Lune-host files (`tests/run.luau`, `tools/*.luau`, specs using `@lune/*`).
- `AGENTS.md` is gone; older docs and `docs/PROGRESS.md` entries may still mention its section numbers.
