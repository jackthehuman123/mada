# Progress

Updated by the agent at the end of every session. Newest session at the top of the log.

## Milestones

- [x] **M0** Toolchain — Rojo build, Studio MCP connected (factory runner), start messages print
- [x] **M1** Graybox village — all places built, tagged, walkable; night lighting; boundaries
- [x] **M2** Core tools — clues + journal, camcorder (live / record / playback / battery). *Dialogue moved to M3* (Bà Thu's Night 1 scene is its first user).
- [x] **M3 ★** Night 1 — scripted beats 1–7, Bin's tapes, dialogue system *(branch `m3-night1`, not merged)*
- [ ] **M4** Mystery content — all clues, mementos, letter, hints
- [ ] **M5** Sen + taken / rescue + incense
- [ ] **M6 ★** Endings + midnight — full run playable
- [ ] **M7** Art + audio pass
- [ ] **M8** Playtest build (+ optional Stay ending, Quiet Man)

## Current state

The prototype runs end to end: Intro card → Arrival (walk to the shrine with Bin) → Night 1 (the seven scripted
beats: Bà Thu's scene, the lanterns, Bin vanishes, the causeway floods, Bin's camera and tapes) → Open (clock
21:00 → 24:00, "Find Bin.", lanterns again at 23:00, Bà Thu can be talked to again) → Finale → Ending card → reset. The graybox village, the clue/journal
system, the camcorder and the boundaries work. Everything is built from git (see `docs/FACTORY.md`) and checked by
`python tools/factory/test.py` (6 test files, all passing). This is the brief's "Chapter 1 teaser" stop point. Next: **M4** (all clues and mementos, the letter, hint flicker).

## Session log

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
