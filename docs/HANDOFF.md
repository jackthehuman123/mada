# Handoff: integration and build testing (local session with Studio)

For any local Claude Code session (or person) with Roblox Studio open, picking up build testing. Asked for in
issue #6. The GitHub bot can't run Studio or the tests, so this part is done on a computer. First-time setup on a new
computer: `docs/SETUP.md` §1–§5 (or the `/setup` skill if it's installed).

Paste this into Claude Code in your `mada` checkout, or follow it by hand:

> Follow `docs/HANDOFF.md` from the top and tick each box as you go.

## 1. Get onto the newest build

- [ ] `git fetch` then `git checkout full-game` and `git pull`. The newest work is on `full-game`, not `main`.
- [ ] Read `docs/PROGRESS.md` **on that branch**: current milestone, the "Next" list, known bugs.
- [ ] `rokit install` (gets Rojo); `rojo --version` works.

## 2. Studio connection and code sync (`AGENTS.md` §2)

- [ ] Studio is open with the place. The MCP tool `list_roblox_studios` returns it. If not, stop and follow
      `docs/MCP_SETUP.md`.
- [ ] `rojo serve`, click **Connect** in the Rojo plugin. `search_game_tree` shows `ServerScriptService.Server` and
      `ReplicatedStorage.Shared`.

## 3. Integration check: one manual playtest

- [ ] `start_stop_play` → `get_console_output`: **zero errors from our scripts** (Studio and plugin noise is fine; note it).
- [ ] Walk the phases with the debug commands (`docs/FACTORY.md`): `/lv phase Open`, `/lv goto SenHouse`,
      `/lv clue all`, `/lv time 23.9`, `/lv battery 20`, `/lv reset`. `screen_capture` anything that looks wrong.
- [ ] Stop play. Don't edit while a playtest is running.

## 4. Build check: the factory tests

Only when no other agent is using Studio (`AGENTS.md` §10): it opens its own Studio window for about 2 minutes.

- [ ] `python tools/factory/test.py` → **PASS**. Report: `tools/factory/reports/<time>/report.md` (not committed).
- [ ] If anything fails, rerun only that file (e.g. `python tools/factory/test.py 06`), fix it in `src/` or `tests/`,
      then rerun the whole suite.

| Test | Covers |
| --- | --- |
| `01_boot` | M0: server and client boot from git, world built |
| `02_world` | M1: every place tagged and reachable, night lighting, boundaries |
| `03_clues` | M2: clue prompt, panel, shared journal |
| `04_camcorder` | M2: hidden/camera-only objects, playback, battery drain and recharge |
| `05_phases` | Shrine → Night 1 → Open → midnight → Finale → Ending, reset |
| `06_night1` | M3: Night 1 beats 1–7, both tapes, flooded causeway |
| `07_mystery` | M4: every clue and memento, the letter, stuck hint, carp steps |
| `08_sen` | M5: the five warnings, taken, lantern, incense rescue |
| `09_endings` | M6: Về nhà, Ở lại, Im lặng, reset after |

## 5. QA on M7/M8

- [ ] Run the `qa-tester` subagent on M7 and M8 as they stand (only it uses Studio at that moment).
- [ ] Fix its findings, ask it to re-check, until it reports **PASS** or what's left is written down as a known bug.

## 6. Write it down and hand back

- [ ] `docs/PROGRESS.md`: what passed, **how you checked it** (test run time, debug commands, screenshots), known bugs.
- [ ] `docs/DECISIONS.md`: one line for each choice the docs didn't settle.
- [ ] Commit on a branch (not `main`), e.g. `test/issue-6-<date>`, push, open a pull request into `full-game`.
- [ ] **Save the place in Studio** (File → Save or Publish): the art layer lives in the place, not in git.
- [ ] Post a short summary on issue #6: PASS/FAIL per test, console errors, QA result, link to the pull request.
