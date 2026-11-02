# Làng Vọng test report 20261102-225523

- Commit: `2656c5d` + uncommitted changes
- Result: **FAIL** — 0 tests passed, 9 failed, 6 console errors

| Test | Section | Status | Detail |
|---|---|---|---|
| 01_boot | Server | ❌ | no 'server started' line |
| 02_world | Server | ❌ | missing Location Shrine |
| 03_clues | Server | ❌ | no Look prompt on Workspace.World.Village.TeacherHouse.Report |
| 04_camcorder | Server | ❌ | ServerScriptService.Server.Services.DebugService:125: no location Shrine or no character |
| 05_phases | Server | ❌ | ServerScriptService.Server.Services.DebugService:125: no location Shrine or no character |
| 06_night1 | Server | ❌ | ServerScriptService.Server.Services.NightOneDirector:221: attempt to index nil with 'Exists' |
| 07_mystery | Server | ❌ | no Look prompt on Workspace.World.Village.TeacherHouse.Report |
| 08_sen | Server | ❌ | ServerScriptService.Server.Services.DebugService:125: no location Dock or no character |
| 09_endings | Server | ❌ | ServerScriptService.Server.Services.DebugService:125: no location Shrine or no character |

## Console errors

```
[Server] Ceramic is not a valid member of "Enum.Material"
```
```
[Server] ServerScriptService.Server.Services.DebugService:125: no location Shrine or no character
```
```
[Server] ServerScriptService.Server.Services.DebugService:125: no location Shrine or no character
```
```
[Server] ServerScriptService.Server.Services.NightOneDirector:221: attempt to index nil with 'Exists'
```
```
[Server] ServerScriptService.Server.Services.DebugService:125: no location Dock or no character
```
```
[Server] ServerScriptService.Server.Services.DebugService:125: no location Shrine or no character
```
