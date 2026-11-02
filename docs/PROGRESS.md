# Progress

Updated by the agent at the end of every session. Newest session at the top of the log.

## Milestones

- [x] **M0** Toolchain — Rojo build, Studio MCP connected (factory runner), start messages print
- [x] **M1** Graybox village — all places built, tagged, walkable; night lighting; boundaries
- [x] **M2** Core tools — clues + journal, camcorder (live / record / playback / battery). *Dialogue moved to M3* (Bà Thu's Night 1 scene is its first user).
- [x] **M3 ★** Night 1 — scripted beats 1–7, Bin's tapes, dialogue system *(branch `m3-night1`, not merged)*
- [x] **M4** Mystery content — all clues, mementos, letter, hints *(branch `full-game`)*
- [x] **M5** Sen + taken / rescue + incense *(branch `full-game`)*
- [x] **M6 ★** Endings + midnight — full run playable *(branch `full-game`)*
- [~] **M7** Art + audio pass — audio done (licensed library, no silent ids left, 2026-11-03), graybox dressed in code (houses with pitched roofs, porches, 2026-11-03); the model art pass belongs in the shared place (world-builder), not done
- [~] **M8** Playtest build — analytics summary done; the Stay ending built, then cut by Catlyn (2026-11-02, `Config.StayEnding`); the Quiet Man (optional) left out until after the first playtest (Catlyn, 2026-11-02); publishing the private test place is a human step

## Current state

**A full run is playable from start to finish (branch `full-game`, not merged).** Night 1, then the open village:
15 clues and 4 mementos across the houses, the letter under Sen's altar, the stuck hint, Sen hunting lone players by the
water (taken → drowned festival → rescue with incense), and two endings at midnight (Về nhà, or Im lặng where Sen takes everyone one by one; Ở lại cut 2026-11-02) with the
teller's cards and a playtest summary line. Earlier summary of the run's shape: Intro card → Arrival (walk to the shrine with Bin) → Night 1 (the seven scripted
beats: Bà Thu's scene, the lanterns, Bin vanishes, the causeway floods, Bin's camera and tapes) → Open (clock
21:00 → 24:00, "Find Bin.", lanterns again at 23:00, Bà Thu can be talked to again) → Finale → Ending card → reset. The graybox village, the clue/journal
system, the camcorder and the boundaries work. Everything is built from git (see `docs/FACTORY.md`) and checked by
`python tools/factory/test.py` (9 test files, all passing). Next: a real playtest with 2–4 people, the art pass in the shared place.

## Session log

### 2026-11-02 (evening) — Catlyn's playtest: menu + teams built; houses and characters scouted (branch `playtest-fixes`, off `main`; not merged)
- On the loaner laptop: no Studio, no Python. **Nothing here has been run in Studio.**
- Catlyn's first two playtest issues logged: I-09 (no menu, no teams), I-10 (houses), I-11 (characters).
- **I-09 built:** `Services/MenuService.luau`, `Controllers/MenuController.luau`, `GameStateService.BeginRun`
  (Lobby no longer starts by itself), `Config` menu numbers, `Remotes` MenuAction/MenuState/MenuNotice, `Text.Menu`
  (all DRAFT), debug `begin`/`teams`, `test.py` presses `begin` at startup, `tests/10_menu.luau`. Research: Doors,
  The Mimic, Apeirophobia and DevForum lobby threads all use a menu/lobby server and teleport each group to a reserved
  server (`TeleportOptions.ShouldReserveServer`), which is what this does in one place.
- Verified only statically: `rojo build` OK; `luau-lsp analyze` with the Roblox type definitions: no errors in the
  new/changed code (main already has 83 analyzer errors from older files, unchanged).
- **Scouting without Studio:** new `tools/art/scout.luau` (Lune) searches the Creator Store and saves thumbnails.
  Houses: nothing Vietnamese worth inserting (Thai, Japanese, toy-like); plan in I-10 is generated meshes + store props.
  Characters: plan in I-11 is HumanoidDescription rigs from catalog items; shortlist in `ASSETS.md`.
- **I-12 built:** `BodyController` (locked first person, own body visible but the head, poses for every R15
  character from `LookPitch`/`CameraUp`, head bob, mouse freed for panels) and `BodyService` (visible camcorder prop
  with a REC light, shares `LookPitch`). `CamcorderService` mirrors the viewfinder as `CameraUp`; `hideSelf` sets a
  local `HideSelf` so tape playback still hides the body. `tests/11_body.luau`.
- **I-13 built:** music layer in `SoundController` (menu / bed / tension / chase), four licensed tracks picked by
  name and length (not listened to), alternatives in `ASSETS.md`.
- Verified statically again (`luau-lsp analyze`: no new errors in the changed code).
- **Asset pipeline (Meshy):** `docs/MESHY.md`, `art/meshy/manifest.json` (November's ten queued with prompts),
  `tools/meshy/check.luau` (reads a .glb: triangles, size, textures vs Roblox limits; tested on Khronos Box/Duck
  samples: 12 and 4,212 triangles, correct), `tools/meshy/upload.luau` (Open Cloud upload; not run, needs Catlyn's key).
  Free plan checked on meshy.ai: 100 credits, 10 downloads of untextured Meshy 6 Lite a month, CC BY 4.0, no API.
- Next: on a computer with Studio, `test.py` (11 tests), then 2 clients for I-09 and I-12; listen to I-13; then I-11, I-10.

### 2026-11-03 — verified Catlyn's 11-02 changes; last sounds; houses and finale readable (branch `complete-game`, off `full-game`; not merged)
- Verified first, before any change: `python tools/factory/test.py` on `full-game` 6b9cfb7 → PASS 9/9, 0 console errors. That covers what was written on the loaner without Studio: Ở lại cut (midnight at the steps → Im lặng, the player is taken, no choice and no lantern button), Im lặng taking players one by one, Bin's Tape 2 (hand + under-water shots).
- Done:
  - **Sounds:** the last four silent ids now have Roblox-licensed sounds: `camera_beep`, `memento_ti` (clay whistle), `memento_khoa` (drum), `finale_home` (APM "Hours Before Dawn", 153 s). Finale music is a new `music` flag in `Content/Sounds`: `SoundController` stops it when the phase leaves Finale/Ending (a reset mid-finale no longer leaves music playing). Logged in `docs/ASSETS.md`. Not listened to yet.
  - **Houses** (`Build.luau` `house()`, all 10): the roof was a V (both slabs sloped down to the middle, so it looked like it floated); now a pitched roof with gable ends and a ridge, plus a brick plinth, a porch with posts and a lean-to roof, window shutters, and limewash/tile colours that vary per house (Sen's stays grey). Dressing only: the window, door marker, altar, tags and lantern stops are unchanged.
  - **Finale:** Sen and the children rising in Về nhà get a warm lantern rim (Highlight + a light in front), so they read as children and not dark blocks. Her face stays under her hair.
- Verified by: `python tools/factory/test.py` → PASS 9/9, 0 console errors (report 20261103-021157; shots `06_night1-lit-windows`, `09_endings-finale-home`).
- Not checked by a person yet: the four new sounds; the house look at real speed.
- Next: the human playtest (2–4 players); Creator Store models for the art layer in the shared place, exported with `tools/art/export` (needs Lune trusted: `rokit trust lune-org/lune`).

### 2026-11-02 — M4–M8: the whole run (branch `full-game`, off `m3-night1`; not merged)
- Done:
  - **M4:** all 15 clues of §6 placed and written (DRAFT, story.md only): shrine photos, the teacher's report and Minh's book, the puppet master's diary, the fish seller's notes, the minutes and the spoiled red paper, Sen's doorframe/bowl/chair/paper fish, the sandals on the steps, the letter. 4 mementos with their memories (`Content/Mementos`). The letter under Sen's altar (a Tool: drop with Backspace, pick up by touching). The stuck hint (240 s without a new clue: the nearest house with clues left flickers, a lantern pulses). Carp rise at the steps. `MysteryService`.
  - **M5:** `SenService`: lone players near water in the Open phase get the 5 warnings (crying, carp, camera-only wet footprints, humming with their name, taken). Counters: company, leaving the water, the shrine, incense (2 each, 60 s). Taken → drowned festival (puppet show that never ends, "Light a lantern" every 60 s → hint); incense at the shrine altar (hold 3 s) brings one back, once a night; a second taking is for good; everyone taken → Im lặng.
  - **M6:** `EndingService`: talk to Bà Thu holding the letter → the letter scene → "Write: Sen" → she walks the lane, her back yard and the carp steps → midnight → Về nhà (fish lantern, Sen and the children rise, Thu takes her hand, carp, lanterns carried away, dawn, Bin asleep on the bank). Midnight at the steps without that → Ở lại (hold on / let go; nobody holds → Im lặng). Anything else → Im lặng (every lantern out, static). Teller's cards (DRAFT). Finales abort cleanly on reset. (2026-11-02: Ở lại cut, Im lặng now takes everyone one by one; the cards approved.)
  - **M7 (partly):** audio from Roblox's licensed library (ProSoundEffects): night crickets + lake ambience, underwater for taken players, crying, wet footsteps, splashes, matches, radio click/static, child giggle in lit houses — 15 ids, each checked to load, none listened to yet (`Content/Sounds`, `docs/ASSETS.md`). Silence ending kills all sound. Graybox dressing in code (banana trees, water jars, lotus). The model art pass is world-builder's job in the shared place.
  - **M8 (partly):** `[Analytics] summary …` line at every ending; client events (recordings, playbacks, Bin's tapes) reach the server's analytics. The Stay ending built (gameplay.md), cut 2026-11-02. The Quiet Man: not built (optional), left out for now.
  - Shared `Figures` (Sen and the children, used on the tape and in the finale), `StoryController` (memories, taken button, finale camera/static, Stay choice), dialogue choice buttons.
- Verified by: `python tools/factory/test.py` → PASS 9/9, 0 console errors. New `07_mystery` (14 clues placed with prompts + the letter = 15 in the journal, 4 mementos, a memory plays and ends, the letter from the altar, the stuck hint, carp at the steps), `08_sen` (warnings 1–5 in order → taken to the festival with the letter dropped; the lantern button; rescue at the shrine; the shrine is safe; incense withdraws her; walking away cancels her; second taking for good → everyone taken → Im lặng + summary), `09_endings` (letter → Write: Sen → she walks to the bottom step → Về nhà → card + summary; midnight at the steps → hold on → Ở lại; midnight elsewhere → Im lặng with every lantern out and static; reset brings the lanterns, Bà Thu and the camera back).
- Not checked by a person yet: the whole run at real speed with 2–4 players; how the sounds actually sound; the walk Bà Thu takes; the finale's pacing.
- Unverified (2026-11-02, written on the loaner without Studio): Ở lại cut and Im lặng taking players one by one (`EndingService.silence`, `StoryController` hides the lantern button after the night; `tests/09_endings.luau` updated). Run `python tools/factory/test.py` and watch an Im lặng finale with 2+ players. Also unverified: Bin's Tape 2 now shows him taken (21 s: Sen closer between glitches, her hand takes his, under the water both sink and fade; `Content/Tapes`, `CamcorderController`, `tests/06_night1.luau` has new checks and shots `tape2-hand`, `tape2-under`).
- Next: playtest; Catlyn reviewed every DRAFT text on 2026-11-02 (DECISIONS); still hers once seen/heard: Tape 2 and finale staging, the sounds, the map image; world-builder art pass in the shared place (tested both ways, decided 2026-11-02: export `Workspace.World` to an `.rbxm` the factory tests load, plus a hand playthrough for looks; built 2026-11-02: `tools/art/export.luau` + `merge.luau` checked with Lune on a made-up place (tags, attributes, script removal, Terrain, Lighting, WorldBuilt all carried over); `test.py --art` not run yet; Lune pinned in rokit.toml, see FACTORY.md "Testing the art"); music for the finale; sounds for the whistle and the drum.
- Known issues: Sen and the children read as small dark shapes in the finale (graybox); no music; the warning about asset 203785492 comes from the place, not our code.

### 2026-11-02 — M3 ★ Night 1 (branch `m3-night1`, off `factory-prototype`; not merged)
- Done:
  - `DialogueService` (lines one at a time to a group, any player moves them on, 14 s auto-advance; Bin's remarks as barks; "Talk" to Bà Thu again in Open, one new detail per repeat) + `DialogueController` and the dialogue box.
  - `NightOneDirector`: beats 1–7 (`[Night1] beat N`, attribute `Night1Beat`), clock 19:00 → 21:00 across the beats, the second lantern drift at 23:00.
  - `LanternService`: four lanterns drift ~75 s along `LanternPath` waypoints (new in `Build.luau`) to their houses and light the windows; Sen's stays dark.
  - `BinService`: graybox Bin follows the players, films Bà Thu, walks east along the shore, vanishes when nobody can see him (or after 20 s).
  - Flooded causeway (water + a boundary with the message), Bin's camera in the reeds (blinking REC light, hint after 120 s), Bin's tapes in the camcorder's chooser.
  - `Content/Tapes.luau` (Tape 1 the shrine without Bà Thu, Tape 2 the steps and the girl in the water, ending in static, with handheld shake and the VHS time of the recording); `Content/Sounds.luau` + `SoundController` (subtitles until sounds have assets); `Shared/Pace` (tests run Night 1 25× faster).
  - Fixed on the way: the start-up "infinite yield" warning on the Message remote; a playback race (stopping one tape and starting another).
- Verified by: `python tools/factory/test.py` → PASS, 6/6 files, 0 console errors. New `06_night1`: beat 1 with Bin following; shrine → beat 2 → 3; four windows lit (Head, Fish, Puppet, Teacher), Sen's dark; Bin gone, causeway flooded (walking out returns you in 0.4 s), camera in the reeds; pick-up → Open at 21:00 with the tapes and `[Night1] beat 1..7` in the console; Tape 1 plays at 19:04 without Bà Thu; Tape 2 shows the girl and ends in static, which clears; talking to Bà Thu again opens her repeat; 23:00 sends four lanterns out again; reset clears flood, camera, tapes and windows. Screenshots: lit windows, flood, camera in the reeds, both tapes, the dialogue box.
- Not checked by a person yet: how Night 1 feels at real speed (~4 minutes from the shrine to Open) and with 2–4 players.
- Next: M4 — all clues and mementos (teacher's and fish seller's houses first), the letter under Sen's altar, the stuck-hint flicker.
- Known issues: graybox only; no sound assets (subtitles stand in); the warning about asset 203785492 comes from the place, not our code.

### 2026-11-02 — merged Catlyn's setup into `factory-prototype`
- Merged `main` (SETUP.md, MCP_SETUP §6–7, 5 subagents in `.claude/agents/`, `audio/`, old `contents/` removed).
- Reconciled: world = graybox layer in git (`Build.luau`) + art layer in the shared place; new `tools/worldgen/00_graybox.luau`; `qa-tester` runs `tools/factory/test.py` first; world-builder starts from the baked graybox. Docs: AGENTS §3–4 and Definition of done, README, FACTORY, DECISIONS.
- No code in `src/` changed. Verified: `rojo build` OK; the test runner is unaffected.

### 2026-11-02 — M0, M1, M2 (branch `factory-prototype`)
- Done:
  - Factory tooling: `tools/factory/test.py` (rojo build → own Studio window → play → tests → report → close), `rbx.py`, tests in `tests/`, `docs/FACTORY.md`.
  - World from code: `src/server/World/Build.luau` + `WorldService` (lake, cove, marsh, lane, 10 houses incl. Sen's at the east end, shrine, dock, reeds, causeway + spawn, carp steps behind Sen's yard, far shore + puppet stage, drowned festival at Y −400, water edges, boundaries, night lighting). Every place tagged `Location`.
  - `GameStateService`: phase machine + clock + reset; `ClueService` (Look prompts, group-shared clues, journal sync); `CamcorderService` (battery: drains with the viewfinder up, recharges in the ShrineZone); `BoundaryService` (fade + back to the shore); `DebugService` (Studio-only `Debug` BindableFunction + `/lv` chat commands).
  - Client: `UIController` (text cards, message line, fade, clue panel, journal grouped by place, VHS viewfinder), `ClueController` (J), `CamcorderController` (F / right mouse, R, T; first-person while raised; CameraOnly / HiddenOnCamera local visibility; 10 Hz path recording; playback), `PhaseController`.
  - Content: two test clues (`shrine_redpaper`, `teacher_classphoto`), intro card, placeholder ending card — all marked DRAFT.
- Verified by: `python tools/factory/test.py` → PASS, 5/5 files, 0 console errors:
  - 01_boot: `[LangVong] server started` / `client started`, world built.
  - 02_world: all 12 Locations tagged; a walking path (PathfindingService) from the spawn to all 11 surface places (CarpSteps ~640 studs, SenHouse ~530); 4 LanternStops, 10 windows, water edges, 8 boundary walls; night lighting; walking into the lake boundary returns the player to the shore in 0.7 s. Screenshots: top-down, lane, shrine, Sen's house, carp steps.
  - 03_clues: every Clue has a Look prompt; the red paper and the class photo open the panel and appear in the journal under their places.
  - 04_camcorder: to the eye the footprints are hidden and Bà Thu visible; in the live viewfinder both are visible (FOV 55, VHS overlay); a 2 s clip plays back with Bà Thu gone and the footprints shown, and the world is restored afterwards; clips cap at 3; battery 50 → 49.0 after 3 s up, +10 after 2 s at the shrine.
  - 05_phases: reaching the shrine starts Night 1; Open sets 21:00 and shows "Find Bin."; midnight → Finale; reset → Intro, clues cleared, batteries full, intro card shown.
- Next: M3 — dialogue system, Night 1 director (beats 1–7), lantern drift + window lights, Bin (follow, wander, vanish), flooded causeway, Bin's camera + tapes.
- Known issues: graybox only (plain parts); the carp steps sit low in their cut; the full moon is Roblox's default sky (change in M7).
