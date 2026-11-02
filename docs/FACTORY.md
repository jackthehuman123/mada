# The factory setup: build from git, test without hands

Làng Vọng uses the same architecture as Noptable's Roblox factory (the setup his other games run on). Two rules:

1. **Gameplay comes from git.** Code is in `src/`. The **graybox layer of the world is code too**
   (`src/server/World/Build.luau`, called by `Services/WorldService` at startup only when the place has no world yet).
   A test run and a brand-new place get the same village; `tools/worldgen/00_graybox.luau` bakes it into the shared
   place. The **art layer** (world-builder's dressing and inserted models) lives in the published place, as
   `docs/SETUP.md` §4 describes: save the place after every session. Keep the graybox's names, tags and positions
   when dressing it, so code and tests keep working.
2. **Every change is tested automatically before it's committed.** One command builds the place from git, opens it
   in its own Studio window, plays it, checks every milestone's acceptance test, takes screenshots and closes the window.

## Run the tests

```
python tools/factory/test.py            # every test in tests/
python tools/factory/test.py 04         # only tests starting with 04
python tools/factory/test.py --keep     # leave the Studio window open to look around
```

Needs: Roblox Studio (installed, logged in), `rokit install` in this folder (Rojo), Python 3.10+. Windows today.
It talks to Studio through Studio's own MCP server (`tools/factory/rbx.py`), so no Rojo plugin, no `rojo serve`
and no Claude MCP registration is needed for tests. Output: `tools/factory/reports/<time>/report.md` with a table
of every check, the console errors (any error from our scripts fails the run) and screenshots. Not committed.

A test file (`tests/NN_name.luau`) is split into sections:

```lua
--@ Server
dbg("goto", "Shrine")                 -- the Studio-only debug hook (DebugService): goto, phase, time, clue, battery, reset, get
eq(dbg("get").phase, "Night1", "phase")
return "what the report shows"
--@ Client
local s = cam("raise")                -- the client-side camcorder hook (CamcorderController, Studio only)
check(gui.Viewfinder.Visible, "no VHS overlay")
--@ Shot lane -120,7,-26 -> 120,4,-14  -- screenshot from a camera at the first point looking at the second
```

## Working with Catlyn's setup (`docs/SETUP.md`, `.claude/agents/`)

- The runner works next to Claude Code's own Roblox Studio MCP connection (checked 2026-11-02: three Studio MCP
  connections were open during passing runs). It opens a separate Studio window, so run it only when no other agent
  is using Studio (AGENTS.md §10). `qa-tester` runs it first, then checks by hand what the tests don't cover.
- The tests run on the graybox from git, not on the art in the shared place. Before the art pass (M7) we need a way
  to test the dressed world too (open question in `DECISIONS.md`).

## Working on it day to day

- Edit code in `src/` (as before; `rojo serve` + the plugin still works for live editing in your own Studio).
- Change the graybox layout in `src/server/World/Build.luau`; dress it in the shared place (world-builder) and save the place.
- Before committing: `python tools/factory/test.py` must say PASS.
- Debug in a playtest: chat `/lv phase Open`, `/lv time 23.9`, `/lv goto SenHouse`, `/lv clue all`, `/lv battery 20`, `/lv reset`.

## Files

| Path | What it is |
| --- | --- |
| `tools/factory/test.py` | The test runner (build → own Studio window → play → tests → report → close) |
| `tools/factory/rbx.py` | Minimal client for Studio's built-in MCP server (also usable by hand: `python rbx.py list`) |
| `tools/factory/mute_studio.ps1` | Mutes the Studio window a test run opens |
| `tests/*.luau` | The acceptance checks, one file per area (boot, world, clues, camcorder, phases) |
| `src/server/World/Build.luau` | The graybox village (brief §8), every gameplay object tagged |
