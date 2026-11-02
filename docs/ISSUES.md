# Issues

The work list for Claude sessions. **Read this at the start of every session, pick the first open issue you can do
where you are, and build it.** `docs/PROGRESS.md` is the history (what was done and how it was checked); this file is
what's left.

## How to use it

1. **Start of session:** read this file on `main` (everything is merged there since 2026-11-02). Note whether this
   session has Studio (`list_roblox_studios` answers) or not (GitHub bot, or a computer without Studio).
2. **Pick** the first issue under *Open* whose **Needs** fits: `Studio` issues only in a local session with Studio;
   `no Studio` issues anywhere. Skip anything under *Waiting on Catlyn* or *Parked*.
3. **Build it** following `AGENTS.md` (tests, content rules, one coherent commit per step).
4. **Close it:** move it to *Done* with the date, the commit and how it was checked (the same line goes in
   `PROGRESS.md`). If it's only partly done, say what's left in the issue.
5. **Found a new problem?** Add it under *Open* with the next number. Never reuse a number.

Each issue: **Needs** (`Studio` / `no Studio` / `human`), **Where** (files), **Done when** (the check).

---

## Open

### I-01 · Run the tests on the merged `main`
- **Needs:** Studio.
- **What:** `main` got `complete-game` and `bot-fixes` merged on 2026-11-02 on a laptop without Studio. The merge had
  no conflicts and only docs/bot files differ from `complete-game` (PASS 9/9), but nobody has run it since.
- **Done when:** `python tools/factory/test.py` on `main` → PASS 9/9, 0 console errors.

### I-08 · Catlyn's first playtest: write down what went wrong
- **Needs:** no Studio to write the issues; then each fix as its own issue.
- **What:** Catlyn played the prototype on 2026-11-02 and found "a lot of bad things". Ask her for the list, then add
  each one here as its own issue (I-09, I-10, …) with what she saw, where, and what "fixed" looks like.
- **Done when:** every problem she reports is an open issue here.

### I-02 · Art pass: Creator Store models in the shared place
- **Needs:** Studio (`world-builder` subagent).
- **Where:** the shared place, `Workspace.World.<Area>`; `docs/ASSETS.md`; `tools/art/`.
- **What:** dress the graybox with free models (houses, shrine, dock, reeds, lanterns, puppet stage) keeping every
  name, tag and position the code uses. Sanitize every model (`AGENTS.md` §7). Before the first export:
  `rokit trust lune-org/lune`.
- **Done when:** `tools/art/export` writes `art/*.rbxm`, `python tools/factory/test.py --art` → PASS (it has never
  been run), screenshots of each area in `PROGRESS.md`, every asset logged in `ASSETS.md`.

### I-03 · QA pass on M7 and M8
- **Needs:** Studio (`qa-tester` subagent; nothing else using Studio at the time).
- **What:** acceptance checks, console errors, unsafe-script scan, content rules and story accuracy on the build as it
  stands (`docs/HANDOFF.md` §5 on the issue-6 branch).
- **Done when:** `qa-tester` reports PASS, or every finding is fixed or added here as an issue.

### I-04 · Get the build ready for the first human playtest (2–4 players)
- **Needs:** no Studio for the checklist; human for publishing (private test place, `AGENTS.md` §9).
- **What:** write `docs/PLAYTEST.md`: how to join, what to try, what to watch for (Night 1 pacing ~4 min, the stuck
  hint, Sen's warnings, Im lặng with 2+ players, the finale), and a short feedback form. Point to the
  `[Analytics] summary` line for numbers.
- **Done when:** the checklist exists and Catlyn has a place to publish it to. The playtest itself is hers.

### I-05 · Carp steps sit low in their cut
- **Needs:** Studio (to look); the fix is in code.
- **Where:** `src/server/World/Build.luau` (carp steps). Known since M1, never rechecked.
- **Done when:** a screenshot shows the steps reading clearly from the cove; `test.py` PASS (`02_world`, `09_endings`).

### I-06 · Night sky is Roblox's default
- **Needs:** Studio (to look); the sky can be set in code.
- **Where:** night lighting in `Build.luau` (or the art layer). Known since M1 ("change in M7").
- **Done when:** a full moon / sky that fits the lake village, screenshot in `PROGRESS.md`, `test.py` PASS.

### I-07 · Console warning about asset 203785492
- **Needs:** Studio.
- **What:** the warning comes from something in the place, not our code. Find what uses it and remove or replace it.
- **Done when:** a playtest starts with the warning gone.

---

## Waiting on Catlyn

Claude doesn't pick these up; when Catlyn gives an answer or a file, turn it into an open issue.

- **W-01 · Listen to the sounds** — all of them, especially the four added 2026-11-03 (camera beep, Tí's clay
  whistle, Khoa's drum, Về nhà music). None has been listened to. Swap ids in `src/shared/Content/Sounds.luau`.
- **W-02 · Look at the new houses and the finale glow** at real speed (2026-11-03, `Build.luau` `house()`,
  `EndingService` `home()`).
- **W-03 · Tape 2 staging and the story.md §13 wording** once seen in Studio.
- **W-04 · Finale staging** (Về nhà, Im lặng) once seen.
- **W-05 · The village map image** `docs/design/map.png`; then update `PROTOTYPE_BRIEF.md` §8 and the map constants
  in `Build.luau`.

Studio isn't usable on the loaner laptop (2026-11); W-01 to W-04 wait for a computer with Studio.

## Parked

- **The Quiet Man / Silence** — left out until after the first playtest (Catlyn, 2026-11-02).
- **Ở lại (Stay) ending** — cut by Catlyn 2026-11-02 (`Config.StayEnding`). Don't bring it back unless she asks.

## Done

- **2026-11-02** · Branches merged into `main`: `complete-game` (which holds `full-game`, `m3-night1`,
  `factory-prototype`) and `bot-fixes`. No conflicts. `claude/issue-6-20261102-1840` (`docs/HANDOFF.md`) not merged:
  this file replaces its checklist. Tests not rerun yet (I-01).

- **2026-11-03** · Tests on Catlyn's 11-02 changes (Ở lại cut, Im lặng one by one, Tape 2) → `test.py` PASS 9/9,
  0 console errors (`complete-game` 29d6bc2).
- **2026-11-03** · Last four silent sounds filled; finale music stops on reset (`complete-game` 29d6bc2).
- **2026-11-03** · Graybox houses readable (pitched roofs, porches); finale figures lit (`complete-game` 29d6bc2).
