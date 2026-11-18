---
name: edit-scene
description: Use when Catlyn asks to change how a scene looks or is laid out (props, positions, lighting, fog, colours).
---

Golden example: `src/server/Scenes/village/` (`layout.luau`, `mood.luau`).

1. Map her request to edits in the scene's `layout.luau` and/or `mood.luau`.
2. Send the edit to the `world-builder` agent. It edits only those two files.
3. If a needed piece has no prefab, stop and use the `new-prefab` skill; never hand-place parts.
4. Run `tools/check.sh`; it must print `OK`.
5. Tell Catlyn to playtest in Studio.
6. Log her reaction as a new Round in the spec's Feedback log, then commit.
