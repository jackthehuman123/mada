---
name: new-prefab
description: Use when a scene needs a built piece (prop, building, object) that does not exist in assets/prefabs yet.
---

Golden example: `tools/extract-prefabs.luau`.

1. Agree the prefab name (`^[A-Za-z][A-Za-z0-9_]*$`, unique) and a one-line purpose with Catlyn.
2. Build it as a Model inside `Workspace.PrefabWorkshop` in Studio (Catlyn, or `studio-tester` via MCP).
3. Catlyn saves the place to `work/workshop.rbxl`.
4. Run `lune run tools/extract-prefabs work/workshop.rbxl`.
5. Run `tools/check.sh`; it must print `OK`.
6. Commit the new `assets/prefabs/<Name>.rbxm`. Never read the `.rbxm` or `.rbxl` files.
7. Return to the `edit-scene` skill to use it in a layout.
