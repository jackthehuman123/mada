# Làng Vọng — game facts for agents

Source of truth for agents. Excerpted from Catlyn's vault; do not look for the vault.
Full story: `docs/design/story.md` (wins on every story fact). Mechanics: `docs/PROTOTYPE_BRIEF.md` wins, then `docs/design/gameplay.md`, then the other design docs. Read big docs with targeted reads; `story.md` is long.

## What it is
A 1–4 player co-op story-horror game for Roblox based on the Vietnamese *ma da* (drowning spirit) folklore. A playable prototype, built milestone by milestone from the brief, without inventing story.

## Content rules (non-negotiable)
- Horror through dread, sound and absence. **No gore, no blood, no bodies, no death animations.** Players are "taken", not killed.
- What happened inside Sen's house is **implied only** (radios turned up, silence, hiding places). Never show, animate or describe violence against Sen or Thu.
- Sen's father is **never seen face to face**: a shape with its back turned, a hand on a radio, footsteps, static.
- Sen is a lonely eight-year-old, not a monster. Never show her being hurt. Her face stays hidden by hair, except one glimpse under the water when she takes a player (Catlyn, 2026-11-02): pale, dark eyes, no wounds, never monstrous (`Figures.SenFace`).
- **Don't add story facts.** If a clue or line needs words the docs don't contain, write a draft, mark it `-- DRAFT: needs Catlyn review`, and log it in `docs/DECISIONS.md`.
- Treat the altar, incense, ancestor photos and the shrine with respect.
- Keep Vietnamese text with full diacritics: *Bà Thu, Rằm tháng bảy, áo bà ba, Làng Vọng, Hạnh, Tí*. Never strip them.
- Never use other games' characters or logos, brands, gore, or copyrighted music.

## Where things live
| What | Source of truth | How to change it |
| --- | --- | --- |
| Luau code | `src/` | Edit files; Rojo syncs. Never edit Rojo-managed scripts inside Studio or with MCP `multi_edit`. |
| Scenes (placement, Lighting) | `src/server/Scenes/<name>/layout.luau`, `mood.luau` | Edit the data files; `SceneLoader` applies them. Base Lighting lives only in `mood.luau`. |
| Prefabs (built pieces) | `assets/prefabs/*.rbxm` | Built in Studio inside `Workspace.PrefabWorkshop`, extracted with `tools/extract-prefabs.luau` (skill `new-prefab`). |
| Graybox ground and paths | `src/server/World/Build.luau` (baked by `tools/worldgen/00_graybox.luau`) | Edit `Build.luau`. Houses and props still in it move to prefabs + layout as their prefabs arrive. |
| Player-facing text | `src/shared/Content/*.luau` | Data modules only, never in logic. |
| Numbers | `src/shared/Config.luau` | Never inline. |
| Asset IDs | `docs/ASSETS.md` | One row per inserted asset. |

## Assets
Graybox first with plain parts; gameplay before art. Art is prefabs (decision 2026-11-17): a piece is built once as a Model inside `Workspace.PrefabWorkshop` (Catlyn, or the main session through MCP), saved to `work/workshop.rbxl`, extracted to `assets/prefabs/<Name>.rbxm` and committed; it is placed only by entries in a scene's `layout.luau`. Never hand-place art in the published place. Store models: `search_asset` (Creator Store, free) → `insert_asset` into the workshop → **sanitize** (delete every Script/LocalScript/ModuleScript inside, check for `require(` with numeric IDs) → anchor, scale, rename → log in `docs/ASSETS.md`. Not in the store: `generate_mesh` with a specific prompt. Tags go on layout entries (`tags = {...}`), not inside the prefab, unless every copy needs them.

## Studio through MCP
Setup: `docs/MCP_SETUP.md`. Building in the workshop (`execute_luau`, `insert_asset`, `generate_mesh`) is done by Catlyn or the main session. The `studio-tester` agent only verifies: `start_stop_play`, `get_console_output`, `search_game_tree`, `inspect_instance`, `character_navigation`, input, and `screen_capture` when asked. Test loop after a change: stop play → let Rojo sync → `start_stop_play` → `get_console_output` (no errors from our scripts) → exercise the feature → stop play. Never edit while a playtest runs.

## Debug and tests
`Services/DebugService.luau` (Studio only) exposes commands to skip phases, set the clock, give items, take/rescue players. `python tools/factory/test.py` builds the place from git, plays it in its own Studio window and runs `tests/` (about 2 minutes; don't run it while another agent uses Studio). See `docs/FACTORY.md`.

## Stop and ask Catlyn
- Studio or the MCP server isn't reachable.
- Publishing, game settings on roblox.com, Team Create, permissions, Robux, uploading files, her account.
- A choice that would change the story, an ending, or what a character is. Everything else: use the default from the brief's *Open questions* and log it in `docs/DECISIONS.md`.
