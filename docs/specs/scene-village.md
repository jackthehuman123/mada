# Spec: scene — village

## Goal
The village scene's look as data: which prefabs stand where (`layout.luau`) and the base night Lighting (`mood.luau`), loaded at server start by `SceneLoader`.

## Files touched
- `src/server/Scenes/village/layout.luau` — prefab placements (`{ prefab, at = {x, y, z}, rot?, tags? }`)
- `src/server/Scenes/village/mood.luau` — base Lighting and atmosphere

## API
`SceneLoader.load("village")`; entry and mood fields are defined in `src/shared/Scene/Layout.luau` and `Mood.luau`. Prefab names: `lune run tools/list-prefabs`. Tags come from `src/shared/Tags.luau`.

## Edge cases
- A layout entry names a prefab that doesn't exist: `tools/check.sh` fails naming the entry; at runtime it is skipped with a warning.
- `mood.clockTime` only sets the edit-mode time; during play `GameStateService` owns the time of day.
- Graybox ground and paths stay in `World/Build.luau`; placements here must not block its paths.

## Acceptance checks
- [lune] `tests/scenes_reference_prefabs.spec.luau` passes (every entry names an existing prefab; mood validates).
- [playtest] Server start prints `[LangVong] scene village: N prefabs placed` and no scene warnings.
- [playtest] At night the shore, the paths and the water read on the dock, the causeway and the lane; still night.

## Out of scope
- The graybox in `World/Build.luau`, time of day during play, building prefabs (skill `new-prefab`).

## Feedback log
<!-- Newest round last. Builders read every "Decided" line before changing anything. -->
### Round 1 — 2026-11-04
- Catlyn said: (recorded in `World/Build.luau` notes) ambient 40/46/66 and 50/58/84 played pitch black on the dock; round 2: still black frames outdoors on the causeway, the lane and the dock.
- Decided: more moonlight and a little exposure; still night (brightness 1.6, ambient 74/82/108, outdoor ambient 112/124/158, exposure 0.25, fog 40–420).
- Decided: atmosphere density 0.3 (0.42 hid the karst towers' feet in haze); a dark atmosphere colour (a light haze made the sky between the towers read as a ceiling).

### Round 2 — 2026-11-17
- Catlyn said: the village mood takes her Nov 4 tuned values; art is prefabs placed by this layout.
- Decided: base Lighting lives only in `village/mood.luau` (moved out of `Build.luau`).
- Decided: `clockTime` is the edit-mode starting value only; `GameStateService` owns time of day in play.
- Decided: built pieces are prefabs in `assets/prefabs/`, placed only by `layout.luau` (`docs/DECISIONS.md`, 2026-11-17).
