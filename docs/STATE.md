# State

History is in `docs/PROGRESS.md`; open work in `docs/ISSUES.md`. Keep this file ≤ 40 lines.

## Milestone
Playtest build. Everything is merged on `main`; the factory-2 branch (`factory-2`) is reworking the agent setup and the scene pipeline.

## Done
- M0–M6: toolchain, graybox village, clues and camcorder, Night 1, mystery content, Sen and rescue, endings and midnight (a full run is playable).
- M7 partly: audio pass done, graybox dressed in code; model art pass not done.
- M8 partly: analytics summary, menu and teams; the Stay ending was cut; the Quiet Man is left out until after the first playtest.
- Factory 2.0 Tasks 1–8 done (`docs/superpowers/plans/2026-11-17-roblox-factory-2.md`): `tools/check.sh` (all of `src/`, type-error ratchet in `tools/type-baseline.txt`), post-edit hook, permissions, scene data + validators, `SceneLoader`, prefab extract/list tools, lean docs, agents with fixed models, skills. Task 4's Studio check passed manually 2026-11-17.
- Review fixes (2026-11-17): base Lighting only from `village/mood.luau` (Catlyn's tuned night); art = prefabs placed by `layout.luau`; one finish routine in `CLAUDE.md`; village spec `docs/specs/scene-village.md`.

## Next
- Factory 2.0 Task 9: its first run creates `docs/BASELINE.md` as the baseline (Task 0 was skipped); later runs compare against it.
- A real playtest with 2–4 people; the art pass as prefabs (I-02).

## Known issues
- `village/layout.luau` is empty: no prefabs placed until the workshop is extracted into `assets/prefabs/`.
- 94 legacy type errors (I-19); deprecated `LoadCharacter`/`IsInGroup` (I-18).
- `luau-lsp` doesn't typecheck Lune-host files (`tests/run.luau`, `tools/*.luau`, specs using `@lune/*`).
- `AGENTS.md` is gone; older docs and `docs/PROGRESS.md` entries may still mention its section numbers.
