# Decisions

Choices made during the build that the design docs didn't settle, and drafts that need Catlyn's review. One line each. The defaults already listed in `PROTOTYPE_BRIEF.md` §12 don't need repeating here.

| Date | Decision / draft | Why | How to change it | Needs Catlyn? |
| --- | --- | --- | --- | --- |
| 2026-11-01 | Design docs' embedded structure diagram and village map didn't export; `PROTOTYPE_BRIEF.md` §8 is a text stand-in. | Images missing from the export. | Add `docs/design/map.png` and update §8. | Yes |
| 2026-11-02 | The graybox world is built by the server from code (`src/server/World/Build.luau`), not saved in the place file. | Factory architecture: the world comes from git, survives unsaved places, and the automated tests rebuild it every run. | Build in Studio by hand instead and delete the `WorldService` call (then tests need a saved place). | No |
| 2026-11-02 | Map coordinates follow §8's text map: lake north of the village (shore z = −50), lane 590 studs west→east, houses every 55 studs, Teller's old house three doors from Sen's, cove + carp steps east behind a rock ridge, causeway south-west over a marsh. | §8 is a text stand-in until the real map exists. | Edit the constants and functions at the top of `Build.luau`. | Yes (when the map image exists) |
| 2026-11-02 | Walk speed 12 (Roblox default 16): the lane takes ~50 s end to end. | Brief §8: lane ≈ 60 s of walking; slower also suits the mood. | `Config.WalkSpeed`. | No |
| 2026-11-02 | Battery: 300 s of viewfinder time (drain 0.33 %/s), not 1 %/s. | §5.2 says both "1 %/s" and "300 s"; they disagree (1 %/s = 100 s). Picked the 300 s figure. | `Config.CameraBatterySeconds` / `CameraDrainPerSecond`. | Yes |
| 2026-11-02 | The viewfinder is first person (camera locked to the head) while raised; the player's own body is hidden on playback. | Third person put the player's avatar in front of everything filmed; a camcorder is held to the eye. | `CamcorderController` (`LockFirstPerson`, `hideSelf`). | No |
| 2026-11-02 | Playback shows every CameraOnly object (not only the logged ghost events), and other players where they are now. | Prototype: the CameraOnly things so far don't move, so the result is the same; events are logged in each clip for when they do. | `CamcorderController.Play`. | No |
| 2026-11-02 | Workspace.StreamingEnabled = false (in `default.project.json`). | Small map; the camera's local visibility tricks need every tagged part present on the client. | Turn it on and make the camcorder listen for streamed-in parts. | No |
| 2026-11-02 | The shrine's altar stands on the lake side facing the lane; Bà Thu sits on her mat in front of it, facing visitors. | Coming from the lane you met the altar's back, and it hid her. | `shrine()` in `Build.luau`. | Yes |
| 2026-11-02 | Night 1 is a placeholder until M3: the phase waits 8 s (clock 19:00 → 21:00) and shows "(Night 1 is not built yet: M3)". | Keeps the run playable end to end before the director exists. | `Config.Night1PlaceholderSeconds`; replaced by the NightOneDirector in M3. | No |
| 2026-11-02 | DRAFT texts: the two test clues (`Content/Clues.luau`), the intro card and the placeholder ending card (`Content/Text.luau`). | Written from story.md and brief §3/§7 for M2 testing. | Edit the Content modules. | Yes |
| 2026-11-02 | Debug commands: Studio-only `ServerScriptService.Debug` BindableFunction (used by the tests) and `/lv` chat commands with the same verbs. | AGENTS.md §5; the factory tests drive the game through it. | `DebugService`. | No |
