---
name: edit-scene
description: Use when Catlyn asks to change how a scene looks or is laid out (props, positions, lighting, fog, colours).
---

Example: `src/server/Scenes/village/` (`layout.luau` has a commented example entry; `mood.luau` the tuned night).
Spec and Feedback log: `docs/specs/scene-<name>.md` (village: `docs/specs/scene-village.md`).

1. Read every "Decided" line in the scene's spec. If her request conflicts with one, ask before going on.
2. Add a new Round to the spec's Feedback log: her words, quoted, and a `Decided:` line per change.
3. Send the request and the spec path to the `world-builder` agent. It edits only `layout.luau` / `mood.luau`, runs `tools/check.sh` and adds a `Changed:` line.
4. If it proposes a new prefab, stop and use the `new-prefab` skill; never hand-place parts.
5. Tell Catlyn to playtest in Studio. Her reaction goes into the next Round (skill `iterate`).
6. Do the CLAUDE.md finish routine.
