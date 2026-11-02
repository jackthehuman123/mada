# World generation scripts

Luau scripts that build the world in Studio, run by the agent with the MCP `execute_luau` tool (Edit context). They are **not** synced by Rojo and don't run in the game.

Why: the place file isn't in git, so anything built only by hand in Studio can't be rebuilt or reviewed. Builder scripts make the world reproducible.

Conventions:

- One script per area: `01_terrain_lake.luau`, `02_lane_and_houses.luau`, `03_shrine.luau`, `04_sen_house_and_steps.luau`, `05_causeway_and_boundaries.luau`, `06_lantern_paths.luau`, `07_drowned_festival.luau`, `08_lighting.luau`.
- Each script is **idempotent**: it first destroys `Workspace.World.<Area>` if present, then rebuilds it.
- Everything goes under `Workspace.World.<Area>` and gets the tags/attributes from `src/shared/Tags.luau`.
- Layout and sizes follow `docs/PROTOTYPE_BRIEF.md` §8. Put the key coordinates in a table at the top of each script.
- When the art pass replaces graybox parts with assets, keep the same names, tags and positions so code keeps working.
