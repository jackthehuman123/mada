---
name: new-prefab
description: Use when a scene needs a built piece (prop, building, object) that does not exist in assets/prefabs yet.
---

1. Agree the prefab name (`^[A-Za-z][A-Za-z0-9_]*$`, unique ignoring case; check `lune run tools/list-prefabs`) and a one-line purpose with Catlyn.
2. Build it as a Model inside `Workspace.PrefabWorkshop` in Studio: Catlyn, or the main session through MCP (`execute_luau`, `insert_asset`; sanitize store models per `docs/GAME.md`). `studio-tester` never builds.
3. Catlyn saves the place to `work/workshop.rbxl`.
4. Run `lune run tools/extract-prefabs work/workshop.rbxl`, then `tools/check.sh` (the only check run for this change; it catches a prefab Rojo can't read).
5. Optional: `studio-tester` verifies it loads (placed once via a layout entry, no console errors).
6. Never read the `.rbxm` or `.rbxl` files. To place it, use the `edit-scene` skill.
7. Do the CLAUDE.md finish routine.
