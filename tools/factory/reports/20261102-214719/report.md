# Làng Vọng test report 20261102-214719

- Commit: `34e16e6` + uncommitted changes
- Result: **PASS** — 6 tests passed, 0 failed, 0 console errors

| Test | Section | Status | Detail |
|---|---|---|---|
| 01_boot | Server | ✅ | server started, world built, phase Intro |
| 01_boot | Client | ✅ | client started, UI built |
| 02_world | Server | ✅ | 12 places tagged; lanterns stops, windows, water edges, boundaries ok |
| 02_world | Server | ✅ | walkable from the spawn: CarpSteps 638, Causeway 34, CommunalHouse 39, Dock 166, FishHouse 148, HeadHouse 93, PuppetHouse 203, SenHouse 533, Shrine 94, TeacherHouse 258, TellerHouse 368 |
| 02_world | Server | ✅ | returned to the shore in 0.6 s |
| 02_world | Client | ✅ | card cleared |
| 03_clues | Server | ✅ | 2 clues have a Look prompt; red paper found |
| 03_clues | Client | ✅ | panel shows the red paper; journal lists it under the shrine |
| 03_clues | Server | ✅ | class photo found: shrine_redpaper, teacher_classphoto |
| 03_clues | Client | ✅ |  |
| 03_clues | Client | ✅ | journal shows both, grouped by place |
| 04_camcorder | Server | ✅ | at the shrine, facing Bà Thu |
| 04_camcorder | Client | ✅ | eyes: no footprints, Bà Thu there; viewfinder: both; recorded a 2 s clip |
| 04_camcorder | Client | ✅ | playback: Bà Thu gone, footprints shown |
| 04_camcorder | Client | ✅ | playback ended and restored the world; clips capped at 3 |
| 04_camcorder | Server | ✅ | at the dock, battery 50 |
| 04_camcorder | Client | ✅ | viewfinder up 3 s |
| 04_camcorder | Server | ✅ | battery 50 -> 49.0 with the viewfinder up; 58.3 after 2 s at the shrine |
| 05_phases | Server | ✅ | shrine -> Night1; Open at 21:00; midnight -> Finale |
| 05_phases | Client | ✅ | message line: Find Bin. |
| 05_phases | Server | ✅ | reset: Intro, no clues, full battery |
| 05_phases | Client | ✅ | intro card: From a video the channel watched last week:  "In Làng Vọn |
| 06_night1 | Server | ✅ | beat 1 with Bin following; shrine -> beat 2 (Bà Thu's scene) -> beat 3 in 5.5 s |
| 06_night1 | Server | ✅ | four lanterns arrived; lit: FishHouse, HeadHouse, PuppetHouse, TeacherHouse; Sen's house dark |
| 06_night1 | Server | ✅ | Bin gone, causeway flooded (back to the shore in 0.4 s), camera in the reeds |
| 06_night1 | Server | ✅ | picked up Bin's camera -> Open at 21:00 with the tapes; console has [Night1] beat 1..7 |
| 06_night1 | Client | ✅ | chooser: Clip1,Clip2,Clip3,Tape1,Tape2; tape 1 plays and Bà Thu isn't on it |
| 06_night1 | Client | ✅ | tape 2: down the steps; the girl stands in the water |
| 06_night1 | Client | ✅ | tape 2 ends in static; the girl is gone with it; Bà Thu back |
| 06_night1 | Server | ✅ | talking to Bà Thu again (Open phase) |
| 06_night1 | Client | ✅ | dialogue: Bà Thu: You're back. Sit, sit. Have some tea. |
| 06_night1 | Server | ✅ | 23:00: the lanterns go out again; reset clears flood, camera, tapes and windows |

## Screenshots

![02_world-top-down.png](02_world-top-down.png)
![02_world-lane.png](02_world-lane.png)
![02_world-shrine.png](02_world-shrine.png)
![02_world-sen-house.png](02_world-sen-house.png)
![02_world-carp-steps.png](02_world-carp-steps.png)
![03_clues-clue-panel.png](03_clues-clue-panel.png)
![03_clues-journal.png](03_clues-journal.png)
![04_camcorder-viewfinder-live.png](04_camcorder-viewfinder-live.png)
![04_camcorder-playback.png](04_camcorder-playback.png)
![05_phases-intro-card.png](05_phases-intro-card.png)
![06_night1-lit-windows.png](06_night1-lit-windows.png)
![06_night1-flooded-causeway.png](06_night1-flooded-causeway.png)
![06_night1-bin-camera.png](06_night1-bin-camera.png)
![06_night1-tape1.png](06_night1-tape1.png)
![06_night1-tape2.png](06_night1-tape2.png)
![06_night1-dialogue.png](06_night1-dialogue.png)
