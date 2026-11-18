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
python tools/factory/test.py --art      # the same tests on the art layer (art/*.rbxm) instead of the graybox
```

Needs: Roblox Studio (installed, logged in), `rokit install` in this folder (Rojo, and Lune for `--art`), Python 3.10+.
Windows today.
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
  is using Studio (CLAUDE.md). `qa-tester` runs it first, then checks by hand what the tests don't cover.
- The tests run on the graybox from git by default. The art is tested both ways (Catlyn, 2026-11-02): by the same
  tests on an export of the art, and by a hand playthrough for looks and mood. See "Testing the art" below.

## Testing the art

The art layer lives in the shared place, so it gets exported into git after each art session:

1. In Studio, with the shared place open: **File → Save to File As… → `build/art-source.rbxl`** (git ignores `build/`).
2. `lune run tools/art/export` writes `art/World.rbxm` (`Workspace.World`) and `art/Environment.rbxm` (the Terrain,
   the Lighting settings and effects). Scripts that came inside free models are removed and listed: delete them in
   the place too.
3. `python tools/factory/test.py --art` merges those files into the place built from git (`tools/art/merge.luau`)
   and runs every test on it. It catches art that breaks gameplay: a model blocking a path, a lost tag, a renamed part.
4. If it passes, commit `art/`. Then play it by hand for the looks (qa-tester screenshots, Catlyn).

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
| `tests/*.luau` | The acceptance checks, one file per area (boot, world, clues, camcorder, phases, Night 1, mystery, Sen, endings) |
| `src/server/World/Build.luau` | The graybox village (brief §8), every gameplay object tagged |
| `tools/art/export.luau`, `tools/art/merge.luau` | Lune scripts: the shared place's art → `art/*.rbxm`, and back into a test build (`--art`) |
| `art/World.rbxm`, `art/Environment.rbxm` | The exported art layer (binary, committed) |
