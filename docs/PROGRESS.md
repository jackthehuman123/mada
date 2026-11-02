# Progress

Updated by the agent at the end of every session. Newest session at the top of the log.

## Milestones

- [x] **M0** Toolchain — Rojo build, Studio MCP connected (factory runner), start messages print
- [x] **M1** Graybox village — all places built, tagged, walkable; night lighting; boundaries
- [x] **M2** Core tools — clues + journal, camcorder (live / record / playback / battery). *Dialogue moved to M3* (Bà Thu's Night 1 scene is its first user).
- [ ] **M3 ★** Night 1 — scripted beats 1–7, Bin's tapes, dialogue system
- [ ] **M4** Mystery content — all clues, mementos, letter, hints
- [ ] **M5** Sen + taken / rescue + incense
- [ ] **M6 ★** Endings + midnight — full run playable
- [ ] **M7** Art + audio pass
- [ ] **M8** Playtest build (+ optional Stay ending, Quiet Man)

## Current state

The prototype runs end to end as a skeleton: Intro card → Arrival (walk to the shrine) → Night 1 (placeholder, 8 s)
→ Open (clock 21:00 → 24:00, "Find Bin.") → Finale → Ending card → reset. The graybox village, the clue/journal
system, the camcorder and the boundaries work. Everything is built from git (see `docs/FACTORY.md`) and checked by
`python tools/factory/test.py` (5 test files, all passing). Next: **M3** (Night 1 director, dialogue, lanterns, Bin).

## Session log

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
