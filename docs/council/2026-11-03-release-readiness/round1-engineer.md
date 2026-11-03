# Round 1: Engineer / QA (live-server failures)

**Score: 4/10 as a live game.** The Studio suite is green but covers one player in the Studio server kind only. Nothing tests Run servers, teleports, the gate or 2-4 players.

1. **MAJOR BUG: a new player may never get the menu state.** `MenuService.luau:397` broadcasts on PlayerAdded, before the client has connected (`MenuController.luau:330`). There is no "sync" action (`onAction`, 224-264). The newcomer sees "no teams" until someone else clicks. Fix: the client sends `sync` once connected, and the server answers with `stateFor`.

2. **MAJOR BUG: a failed teleport leaves the team stuck.**
   - `begin` (198-221) stops after the first `TeleportAsync` that doesn't throw. A later failure only reaches `TeleportInitFailed` (448), which warns. `team.starting` stays true, with no notice.
   - If a member leaves mid-teleport, `players` (171-176) holds a dead Player, so all 3 retries fail.
   - Fix: rebuild the list on each try. On `TeleportInitFailed`, clear `starting`, notify and `broadcast`.

3. **MAJOR DESIGN: a run never ends.** After Ending, `GameStateService.luau:171-173` resets to Intro. "Back to menu" shows only during Ending, about 30 s (`MenuController.luau:272`). A player who misses it replays Night 1. Fix: send the team back to the menu after Ending, and keep the button in Run servers.

4. **MAJOR DESIGN: "Play alone" is one strike.** A solo player is always alone (`SenService.luau:167-179`), and rescue needs a teammate (525-549). So the first taking means all taken, and `checkAllTaken` (251) ends the run about 5 s later. Yet solo is the first button (`MenuController.luau:155`). Fix: a solo rescue at the shrine, or a solo grace rule.

5. **BLOCKER (release config): the playtest gate.** `Config.luau:115` = 5099606, so `PlaytestGate.luau:29` kicks every non-member. Set it to 0 on release day and test with a non-member. Until then, a non-member sees the menu while `IsInGroup` runs and could press Begin.

6. **MAJOR BUG: one client error means a black screen or a frozen camera.**
   - `init.client.luau:22-26` and `init.server.luau:23-27` guard only `require`. One throwing `Init` or `Start` stops every later controller; on the server that means no menu.
   - `SenController.play` (94-260) sets the camera to Scriptable and hides the HUD with no pcall or cleanup path. Any throw mid-scene leaves it frozen for the rest of the run.
   - Fix: pcall each Init/Start, and put the restore block in a protected finally-style path.

7. **MINOR BUG: a late letter loses the good ending.** Bà Thu is still walking (`EndingService.luau:109-144`) when midnight comes. The phase hook does `walking += 1` (550), and `playFinale` sees `thuAtSteps` false (456), so it plays Im lặng although the name was written. Fix: if `NameWritten`, teleport her to the steps and play home.

8. **MINOR BUG: invitees can't follow into a run.** `MenuService.luau:313-322` uses `ServerInstanceId` on a reserved server, which Roblox refuses. It only warns, so the friend waits in the menu with no message.

9. **MINOR BUG: a late arrival can wait forever.** `GameStateService.luau:193-201` returns to Lobby when the last player leaves, and `MenuService.luau:467-472` calls `BeginRun` only once. Someone arriving afterwards sits under "waiting for your team".

10. **MINOR: unthrottled remotes.**
    - `Track` (`GameStateService.luau:184`) accepts any table, and `Analytics.events` (`Analytics.luau:9`) grows until Reset.
    - Every `MenuAction` triggers a `broadcast` (89-97) with `IsFriendsWithAsync` per player per team.
    - Add a per-player rate limit.

11. **MINOR DESIGN: Night 1 can stall forever.** Beat 6 (`NightOneDirector.luau:208-214`) and Arrival (`GameStateService.luau:152`) have no timeout. One AFK team sits there until Roblox idle-kicks them.

12. **MINOR BUG: overlapping hints can leave a window stuck.** `MysteryService.luau:343-357` records `wasMat` and `wasColor` mid-flicker if a second hint starts, so a window can end up permanently dark or neon.

**Not verified:**
- Anything only Roblox's servers show: reserved-server rejoin, `PartyId`, `GetPlayerPlaceInstanceAsync` availability.
- Long-life memory. Per-loop state is cleared (Analytics, Carp, Hint, Footprints and Finale are all cleaned up), but a soak test is still needed.
