# Release Council 2026-11-04: Engineer seat (live-server failures)

**Verdict: SHIP for a group-only playtest. Score 7/10** (round 1: 4/10). No blockers. Four fixes to do before the gate opens to the public (F1-F4).

## Round-1 findings
| # | Finding | Status | Evidence |
|---|---|---|---|
| 1 | Menu state never reaches a new player | Fixed | `MenuController.luau:350` sends `sync` from Init; `MenuService.luau:243` answers with `stateFor`. |
| 2 | Failed teleport leaves the team stuck | Fixed in the menu server, partly elsewhere | List rebuilt each try (`:209-219`). `TeleportInitFailed` clears `starting` and notifies (`:497-508`). It ignores `kind == "Run"` (see F1). |
| 3 | A run never ends | Partly | `SendAllBack` (`MenuService.luau:436`, `GameStateService.luau:174-187`) works when the teleport succeeds. If it fails after TeleportAsync returned ok, the players are stuck (F1). |
| 4 | Solo = one strike | Fixed | Lantern way back (`SenService.luau:736-780`), `checkAllTaken` waits for `TakenFinal` (`:392`). Hardening in F3. |
| 5 | Playtest gate | Still there, as intended | Group id unchanged, so the group-only publish is fine. The check still fails open (F4). The menu still shows to non-members for a moment. |
| 6 | One client or server error kills everything | Mostly fixed | Init is pcalled on both sides, the taking scene is wrapped in a protected `play` that restores camera, HUD and body. `Start` was already isolated by `task.spawn`. |
| 7 | Late letter loses the good ending | Fixed | `EndingService.luau:455-468`. Her walk coroutine is cancelled by the existing phase hook (`walking += 1`). |
| 8 | Invitees can't follow into a run | Partly | Now shows a notice (`MenuService.luau:342`). Still impossible, but no longer silent. Fine for a playtest. |
| 9 | Late arrival waits forever | Fixed | `runArrival` (`:381-385`) calls `BeginRun` when the phase is Lobby. |
| 10 | Unthrottled remotes | Partly | `Track` (0.5 s, 6 plain fields) and `MenuAction` (0.25 s) are limited. `DialogueSkip`, `DialogueAdvance` and `DialogueChoice` are cheap and fine. |
| 11 | Night 1 / Arrival can stall | Not fixed | `NightOneDirector` and `GameStateService` Arrival are untouched. AFK team sits there until Roblox idle-kicks them. Not a playtest blocker. |
| 12 | Hint window stuck | Fixed | Ref-counted `HintFlickers` (`MysteryService.luau:343-372`). |

## New findings
| ID | Sev | Where | Failure scenario | Fix |
|---|---|---|---|---|
| F1 | Major | `MenuService.luau:497` (handler) and `GameStateService.luau:174-187` | `SendAllBack` returns ok (the teleport was only queued), then Roblox fails one later (`TeleportInitFailed`, common on flaky joins). The Run branch is skipped (`kind ~= "Run"`). `InRun` is already false and `leaving` stays true, so that player sits in a dead Ending server, no menu, no reset. | In the handler, for `kind == "Run"`: set `InRun` back to true for that player and retry once after 3 s; if it fails again, `GameState.Reset()` and clear `leaving`. |
| F2 | Medium | `SenService.luau:285-299` (`endWalk`) and `:310-311` (`walkAfter`) | `walkAfter` calls `endWalk`, whose fade-out task runs about 1 s, then ends with `shapeShown(true)`. `walkAfter` has already called `shapeShown(false)`. The water shape reappears next to the walker (two Sens) when a hunt restarts within a second, or after a lane scare. | Give each fade a token; only the latest `endWalk` may re-show the shape, and never while `walker ~= nil`. |
| F3 | Medium | `SenService.luau:392` and `:808-833` | If the World build throws partway (Init is now pcalled, so the server goes on), the festival Stage is missing and the `WayBack` prompt is never made. A solo player taken the first time then has no way back, and `checkAllTaken` never ends the run. Stuck for good. | In `checkAllTaken`, skip the solo grace when no `WayBack` prompt exists. Also `warn` loudly if `wayBackPrompt` finds no stage. |
| F4 | Medium | `PlaytestGate.luau:20-23` | `IsInGroup` fails, so a non-member is let in. For a group-only playtest this lets the public in during a Roblox outage. | Retry 3 times, then kick (fail closed) while the gate is on. |
| F5 | Minor | `SenService.luau:327-331` | The land walk loop `break`s when the target's root is nil (a respawn) and never resumes. Sen stands frozen and visible until the hunt ends. | Use `continue` (or `task.wait` then retry) instead of `break`. |
| F6 | Minor | `Art.luau:32-65`, `Art.place` | One slow or failed mesh delays the whole template folder (serial `CreateMeshPartAsync`). Players can arrive while it builds, and models pop in mid-play. After 60 s the wait gives up and the graybox stays. Meshes are group assets ("Raumania group"), so they should load on live; check this on the first live server. | Build item by item and publish each as it finishes. In a Lobby/Menu server, skip building. |
| F7 | Minor | `SenService.luau:337-355` | The land walk moves a Sen model (many parts) at 20 Hz. Each part replicates separately, a bandwidth cost with 4 players. | Update at 10 Hz, or weld the pieces to the root and move the root. |
| F8 | Minor | `DialogueService.luau:104-117` | Skip needs every player in the audience, so one AFK or taken teammate blocks it (the 14 s auto-advance still works). | Count only players who are alive and not taken. |
| F9 | Minor | `GoalService.luau:80-95` | The recap lists players still in the server. Anyone who left before Ending is not listed. | Cosmetic. Record the names when a player is taken. |

## Checked and fine
- `Skip` ends in a normal return, so `bathu_letter` still gives the good ending. Choice lines are still asked.
- Late-letter teleport uses the same `walkPath` as the walk, and the cancelled walk can't pull her back.
- `FindWayBack` increments `Rescues`, so the second taking is final (`RescuesPerPlayerPerNight = 1`).
- If a teammate leaves after one player is taken, that player becomes solo and gets the way back.
- `LitColor` lanterns reset correctly. The Goal loop is pcalled.
- The lane scare is once per run and cleared in `Reset`.
- `startedOnce` is set before `BeginRun`, and the second late arrival sees Intro, so there is no double begin.

## Not verified
Anything that only real servers show: reserved-server teleport back, group-asset mesh loading, Roblox idle-kick timing, network cost of the walker, and a long soak.

## Verdict
SHIP for the group-only playtest. F1 to F4 should be done before the gate is opened.
