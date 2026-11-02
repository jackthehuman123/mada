# Làng Vọng test report 20261102-190344

- Commit: `5440a30` + uncommitted changes
- Result: **FAIL** — 0 tests passed, 5 failed, 1 console errors

| Test | Section | Status | Detail |
|---|---|---|---|
| 01_boot | Server | ✅ | server started, world built, phase Intro |
| 01_boot | Client | ❌ | no 'client started' line |
| 02_world | Server | ✅ | 12 places tagged; lanterns stops, windows, water edges, boundaries ok |
| 02_world | Server | ✅ | walkable from the spawn: CarpSteps 638, Causeway 34, CommunalHouse 39, Dock 166, FishHouse 148, HeadHouse 93, PuppetHouse 203, SenHouse 533, Shrine 89, TeacherHouse 258, TellerHouse 368 |
| 02_world | Server | ❌ | not returned to the shore: -0.015022494830191135, -2.172494649887085, -133.8282928466797 |
| 03_clues | Server | ✅ | 2 clues have a Look prompt; red paper found |
| 03_clues | Client | ❌ | clue panel not open |
| 04_camcorder | Server | ✅ | at the shrine |
| 04_camcorder | Client | ❌ | AssistantCommand:5: attempt to index nil with 'Invoke' |
| 05_phases | Server | ❌ | phase after reaching the shrine: expected Night1, got Arrival |

## Console errors

```
[Client] GaramondBold is not a valid member of "Enum.Font"
```
