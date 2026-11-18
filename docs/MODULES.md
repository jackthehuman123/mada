# Modules

Index of `src/`. Read this before searching code. Services/controllers all expose `Init()` and `Start()` (omitted below).

## Server (`src/server/`)
| path | purpose | public API |
| --- | --- | --- |
| `init.server.luau` | boots `Services/*`, builds world if missing, loads scenes | — |
| `SceneLoader.luau` | places prefabs from `layout`, applies `mood`; skips unknown prefabs with a warning, clears its own folder first | `load(sceneName): (placed, warnings)` |
| `Scenes/active.luau` | list of scene names to load at boot | returns `{string}` |
| `Scenes/village/layout.luau` | prefab placements (data) | `{Entry}` |
| `Scenes/village/mood.luau` | fog, ambient, clock-time (data) | `Mood` |
| `World/Build.luau` | graybox village, tags and gameplay objects | `function()` |
| `Services/GameStateService` | phase, clock, reset | `GetPhase`, `SetPhase`, `GetClock`, `SetClock`, `OnPhase`, `OnReset`, `InShrine` |
| `Services/MenuService` | menu/run/studio server kind, teams, solo start | `Kind`, `BeginSolo`, `SendAllBack`, `RunEnded`, `Snapshot` |
| `Services/PlaytestGate` | gates playtest servers | — |
| `Services/NightOneDirector` | scripted Night 1 beats | `PickUpCamera`, `Dry`, `State`, `Reset` |
| `Services/DialogueService` | plays conversations from `Content/Dialogue` | `Play`, `Advance`, `Skip`, `Choose`, `Stop`, `StopAll`, `Bark`, `Busy` |
| `Services/BinService` | Bin the cameraman NPC | `Spawn`, `SpawnAsleep`, `Remove`, `Follow`, `StandAt`, `Exists`, `Position`, `Seen` |
| `Services/ClueService` | inspect + found clues | `Inspect`, `Found`, `OnFound`, `Reset` |
| `Services/MysteryService` | mementos, letter, carp, hints | `ViewMemento`, `TakeLetter`, `DropLetter`, `ConsumeLetter`, `LetterHolder`, `LetterFound`, `SpawnCarp`, `Hint` |
| `Services/CamcorderService` | server side of the camcorder | `IsRaised`, `Reset` |
| `Services/LanternService` | lantern windows and drift | `Windows`, `DriftAll`, `Reset` |
| `Services/SenService` | Sen: hunt, take, rescue | `Hunt`, `Hunting`, `Take`, `Rescue`, `Rescuable`, `Alone`, `Exposed`, `Position` |
| `Services/EndingService` | midnight, letter, endings | `GiveLetter`, `CanGiveLetter`, `LetterGiven`, `AllTaken`, `AnswerStay`, `State`, `Reset` |
| `Services/GoalService` | current objective text | `Current` |
| `Services/BodyService` | player body/first-person state | — |
| `Services/BoundaryService` | keeps players inside the village | `Return` |
| `Services/WorldService` | builds graybox world via World/Build if not already built; sets walk speed; removes default Baseplate | — |
| `Services/ArtService` | builds art templates | — |
| `Services/DebugService` | Studio-only debug commands (`/lv`, `ServerScriptService.Debug`) | — |

## Client (`src/client/Controllers/`)
| path | purpose | public API |
| --- | --- | --- |
| `UIController` | ScreenGui, cards, messages, fades | `Gui`, `Card`, `Message`, `Fade`, `ShowDialogue`, `ShowStay`, `SetTaken`, `SetLanternCooldown` |
| `CamcorderController` | camcorder view, record, playback | `Lower`, `Raise`, `ToggleRecord`, `Play`, `PlayTape`, `StopPlayback`, `HasTapes`, `State` |
| `SoundController` | ambience, music, SFX | `Play`, `Ambience`, `Music` |
| `StoryController` | teller cards, story flow | `State` |
| `MenuController` | main menu and team UI | `Render` |
| `SenController`, `BodyController`, `ClueController`, `DialogueController`, `GoalController`, `PhaseController` | client effects for the matching service | — |

## Shared (`src/shared/` → `ReplicatedStorage.Shared`)
| path | purpose | public API |
| --- | --- | --- |
| `Config` | all tunable numbers | table |
| `Tags` | CollectionService tag names | table |
| `Remotes` | creates and returns RemoteEvents | `event(name)` |
| `Scene/Layout` | validates a layout against prefab names | `validate(entries, prefabNames): {string}` |
| `Scene/Mood` | validates a mood table | `validate(mood): {string}` |
| `Art` | clones/places art templates | `build`, `template`, `clone`, `place`, `wait` |
| `Figures` | procedural Sen, hand, children | `Sen`, `SenFace`, `Hand`, `Child` |
| `Analytics` | playtest event log and summary line | `track`, `all`, `summary`, `reset` |
| `Pace` | test-speed time scaling | `scale`, `seconds`, `wait` |
| `Content/*` | player-facing text and data: `Clues`, `Dialogue`, `Mementos`, `Text`, `Tapes`, `Sounds`, `Furniture`, `ArtMeshes`, `Land` | data tables |

## Tools and tests
| path | purpose |
| --- | --- |
| `tools/check.sh` | StyLua, selene, luau-lsp, Lune specs, rojo build; prints `OK` or ≤30 `file:line: message` |
| `tools/extract-prefabs.luau` | `lune run tools/extract-prefabs <place> [folder] [outDir]` → `assets/prefabs/*.rbxm` |
| `tools/lib/prefabNames.luau` | prefab-name rules shared by tools and tests |
| `tools/hooks/post-edit.sh` | format-on-edit hook for `.luau` files |
| `tools/factory/test.py` | builds the place from git, plays it in Studio, runs `tests/NN_*.luau` (`docs/FACTORY.md`) |
| `tests/run.luau`, `tests/*.spec.luau` | Lune runner and pure specs |
