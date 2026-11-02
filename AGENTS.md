# Làng Vọng — instructions for coding agents

You are building a **playable prototype** of *Làng Vọng*, a 1–4 player co-op story-horror game for Roblox based on the Vietnamese *ma da* (drowning spirit) folklore. The design is written; your job is to turn it into a working Roblox place, one milestone at a time, without inventing story.

Read this whole file first. Then do the start-of-session routine below.

---

## 1. Read order

1. `docs/PROTOTYPE_BRIEF.md` — **your spec.** Scope, rules, numbers, map, milestones, acceptance checks, default answers to open questions.
2. `docs/design/story.md` — the full story, told by an old woman. Ground truth for every name, fact and clue.
3. `docs/design/gameplay.md`, `characters.md`, `threats.md`, `timeline.md`, `release-plan.md` — the design docs (some sections are still "to discuss"; the brief gives the default to use).
4. `docs/MCP_SETUP.md` — how Claude talks to Roblox Studio and gets free assets.
5. `docs/ASSETS.md` — asset rules and the log of every asset inserted.
6. `docs/PROGRESS.md` and `docs/DECISIONS.md` — where the last session stopped and what was decided.

**If documents disagree:** for *mechanics*, `PROTOTYPE_BRIEF.md` wins, then `gameplay.md`, then the others. For *story facts* (who did what, names, ages, what a clue says), `story.md` wins over everything.

## 2. Start-of-session routine

1. Read `docs/PROGRESS.md` to find the current milestone and the next unchecked task.
2. Check the Studio connection: call the Roblox Studio MCP tool `list_roblox_studios`. If the tool doesn't exist or returns nothing, **stop** and walk the human through `docs/MCP_SETUP.md`. Don't try to work around it.
3. Check code sync: `rojo --version` works, and `search_game_tree` shows `ServerScriptService.Server` and `ReplicatedStorage.Shared` in the open place. If not, ask the human to run `rojo serve` and click **Connect** in the Rojo plugin.
4. Make a short task list for the session from the milestone's tasks.

## 3. End-of-session / end of each milestone

1. Update `docs/PROGRESS.md`: what's done, **how you verified it**, what's next, known bugs.
2. Log every choice the docs didn't settle in `docs/DECISIONS.md` (one line each: decision, why, how to change it).
3. `git add` + `git commit` with a message like `M2: camcorder record + playback`. Don't push unless the human asks.
4. Tell the human to **save the place in Studio** (File → Save, or Publish). World-builder's geometry and inserted models live in the place, not in git (the graybox layout itself is also in `src/server/World/Build.luau`, see §4).

## 4. Where things live — the rule that prevents lost work

| What | Source of truth | How you change it |
| --- | --- | --- |
| All Luau code | `src/` in git | Edit the files. Rojo syncs them into Studio. **Never** edit Rojo-managed scripts with the MCP `multi_edit` tool or inside Studio: Rojo overwrites them on the next sync. |
| World, graybox layer: layout, gameplay objects, tags | `src/server/World/Build.luau` in git. The server builds it only when the place has no world yet (`Workspace` attribute `WorldBuilt`); the factory tests always run on it. | Main agent edits `Build.luau`. `tools/worldgen/00_graybox.luau` bakes it into the open place. |
| World, art layer: terrain dressing, models, props, lighting polish | The published place (world-builder, `tools/worldgen/NN_area.luau` scripts) | Keep the graybox's names, tags and positions so code and tests keep working. Save the place, then export it to `art/*.rbxm` for `test.py --art` (`docs/FACTORY.md`). |
| Player-facing text (clues, dialogue, UI strings) | `src/shared/Content/*.luau` | Data modules only, never hard-coded in logic. |
| Tunable numbers (timers, distances, battery) | `src/shared/Config.luau` | Never inline magic numbers. |
| Asset IDs and where they're used | `docs/ASSETS.md` | Add a row for every asset you insert. |

## 5. Code conventions

- Luau, `--!strict` at the top of every file, typed function signatures.
- **Server-authoritative:** game phase, clock, clues found, items held, who is taken, endings — all decided on the server. The client does UI, the camcorder view, local visibility tricks and effects.
- Layout (already scaffolded):
  - `src/server/init.server.luau` boots every module in `src/server/Services/` (each returns a table with `Init()` then `Start()`).
  - `src/client/init.client.luau` boots every module in `src/client/Controllers/` the same way.
  - `src/shared/` → `ReplicatedStorage.Shared`: `Config`, `Tags`, `Remotes`, `Content/`, shared types.
- **Find world objects by CollectionService tag**, never by hard-coded `workspace.Foo.Bar` paths. All tag names are constants in `src/shared/Tags.luau`. This lets the world be rebuilt or reskinned without breaking code.
- Remotes are created on the server through `Shared.Remotes`; never create RemoteEvents ad hoc.
- No third-party libraries unless the brief names one. Never keep scripts that come inside free models.
- Keep Vietnamese text with full diacritics: *Bà Thu, Rằm tháng bảy, áo bà ba, Làng Vọng, Hạnh, Tí*. Never strip them.
- A Studio-only debug module (`Services/DebugService.luau`, active only when `RunService:IsStudio()`) exposes commands to skip phases, set the clock, give items and take/rescue players. Build it early; you need it to test.
- If StyLua/Selene are installed (`rokit add JohnnyMorganz/StyLua`, `rokit add Kampfkarren/selene`), format and lint before committing.

## 6. Working with Roblox Studio through MCP

Studio's built-in MCP server gives you these tools (names as Roblox documents them; your client may prefix them, e.g. `mcp__Roblox_Studio__execute_luau`):

| Need | Tool |
| --- | --- |
| Which Studio window to target | `list_roblox_studios` (every call takes a `studio_id`) |
| See the hierarchy / an instance | `search_game_tree`, `inspect_instance` |
| Build or change the world, run one-off code | `execute_luau` (Edit context for building; Server/Client during play for tests) |
| Find and insert **free** models, meshes, decals, audio | `search_asset` → `insert_asset` |
| Make a prop that isn't in the store | `generate_mesh` (text → textured mesh), `generate_material`, `generate_procedural_model` + `wait_job_finished` |
| Playtest | `start_stop_play`, `get_studio_state` |
| Read errors / logs | `get_console_output` |
| Look at the result | `screen_capture` (optionally with camera position/target) |
| Drive the character in a test | `character_navigation`, `user_keyboard_input`, `user_mouse_input` |
| Multi-step exploration or playtest | `subagent` (`explore` / `playtest`) |
| Roblox API docs and best practice | `http_get` (Roblox docs), `skill` |

**Test loop after every change:** stop play if running → let Rojo sync → `start_stop_play` → `get_console_output` (zero errors from our scripts) → exercise the feature (navigation / input / debug commands) → `screen_capture` → stop play. Never edit while a playtest is running.

## 7. Assets (summary — details in `docs/ASSETS.md`)

1. Graybox first with plain parts. Gameplay before art.
2. Art pass: `search_asset` the Creator Store for free assets → `insert_asset` → **sanitize** (delete every Script/LocalScript/ModuleScript inside, check for `require(` with numeric IDs) → anchor, scale, rename, tag, parent under `Workspace.World.<Area>` → log in `ASSETS.md`.
3. Not in the store? `generate_mesh` with a specific prompt (e.g. "small paper carp lantern, folded paper, handmade, lumpy").
4. Never use: other games' characters or logos, brands, gore, copyrighted music.

## 8. Content rules (non-negotiable)

- Horror through dread, sound and absence. **No gore, no blood, no bodies, no death animations.** Players are "taken", not killed.
- What happened inside Sen's house is **implied only** (radios turned up, silence, hiding places). Never show, animate or describe violence against Sen or Thu.
- Sen's father is **never seen face to face**: a shape with its back turned, a hand on a radio, footsteps, static.
- Sen is a lonely eight-year-old, not a monster. Never show her being hurt. In the prototype her face stays hidden by hair.
- **Don't add story facts.** If a clue or line needs words the docs don't contain, write a draft, mark it `-- DRAFT: needs Catlyn review`, and log it in `DECISIONS.md`.
- Treat the altar, incense, ancestor photos and the shrine with respect.

## 9. When to stop and ask the human

- The MCP server isn't reachable or Studio isn't open.
- Anything involving publishing, game settings on roblox.com, Team Create, permissions, Robux, uploading files, or the human's account.
- A design choice that would change the story, an ending, or what a character is. For everything else, use the default from the **Open questions** section of the brief, and log it.

## 10. The agent team (Claude Code subagents)

Specialist subagents live in `.claude/agents/`. The main agent is the **gameplay programmer and lead**: it owns `src/` (except `Content/` text and `Tags.luau` additions), plans each milestone, and delegates:

| Subagent | Use it for | Touches Studio? |
| --- | --- | --- |
| `world-builder` | Terrain, houses, props, lighting, lantern paths, the art pass; free models and generated meshes | Yes |
| `qa-tester` | After every milestone: acceptance checks, console errors, code review, unsafe-script scan, content rules, story accuracy. Read-only. | Yes |
| `story-keeper` | All clue, dialogue, text-card and ending text in `src/shared/Content/` | No |
| `voice-over` | Voice scripts; TTS files if an audio MCP is connected | No |
| `sound-designer` | Ambience, SFX, music: Creator Store first, generated if needed | Only when inserting sounds |

Rules for delegating:
- **Only one agent uses Roblox Studio at a time.** There is one open place and one playtest. Never run `world-builder`, `qa-tester` or the main agent's Studio work in parallel with each other. Agents that don't touch Studio (`story-keeper`, `voice-over`, `sound-designer` while it's only writing lists or generating files) can run in parallel with Studio work.
- Give each subagent a self-contained task: the milestone, the exact section of the brief, the files involved, and what "done" means.
- A milestone isn't done until `qa-tester` reports **PASS**. Fix its findings, then ask it to re-check.
- Record each subagent's report in `docs/PROGRESS.md` (short) and any DRAFT items in `docs/DECISIONS.md`.

## 11. Definition of done (any task)

- `python tools/factory/test.py` says **PASS** (it builds the place from git, plays it in its own Studio window and runs `tests/`). Add or extend a test for every acceptance check you build. Don't run it while another agent is using Studio (§10): it opens a second Studio window for ~2 minutes.

- Code is in `src/`, synced, and committed.
- A playtest starts with **no errors from our scripts** in `get_console_output`.
- The milestone's acceptance check from the brief has been demonstrated, and `PROGRESS.md` says how (debug commands used, what `screen_capture` showed).
