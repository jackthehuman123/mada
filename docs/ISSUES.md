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
- **So far (2026-11-02):** I-09 (no menu, no teams), I-10 (houses), I-11 (characters), I-12 (first person), I-13 (music). More to come.

### I-09 · A menu when players join, and teams of up to 4
- **Needs:** Studio to test; human to set the server size on roblox.com and to test teleports in a published place.
- **What Catlyn saw:** players drop straight into the game with no menu. She wants: join → menu → Play alone or
  Create a team (up to 4, open or private, invite friends) → Begin.
- **How other games do it:** Doors (lobby elevators, 1–4 per run), The Mimic (solo or create a lobby), Apeirophobia
  (UI party, public or private): a lobby/menu server, then each group teleported to its own reserved server.
- **Built (branch `playtest-fixes`, not tested):** `MenuService` + `MenuController`. One place, three kinds of
  server: *Menu* (public: the menu over a slow shot of the lake, teams), *Run* (the reserved server a team is
  teleported to; starts when the whole team is in, or after 40 s), *Studio* (menu, and Begin starts the run in place).
  Teams: open (anyone) or private (the leader's friends and invited players); Invite friends sends the team in the
  invite, and an invited friend in another menu server follows the inviter. "Back to menu" at the ending.
  Debug `begin` skips the menu; `test.py` uses it; new `tests/10_menu.luau`.
- **Done when:** in Studio, the menu shows on Play, Play alone and Create team → Begin both start the run, and with
  2 test players (Test → Clients and Servers) one joins the other's open team; `test.py` PASS 10/10; in the published
  place, two accounts form a team and land in the same run server, and Back to menu returns them. Text marked DRAFT.

### I-10 · Houses look bad: barely any detail
- **Needs:** Studio (`world-builder`) for inserting and dressing; scouting works without Studio (`tools/art/scout.luau`).
- **What Catlyn saw:** "the assets are absolutely horrendous", barely any details. Look for Vietnamese / Southeast
  Asian / old houses.
- **Scouted 2026-11-02 (see the shortlist in `ASSETS.md`):** the free Creator Store has almost no Vietnamese
  village houses. What comes up is Thai, Japanese, Chinese-fantasy or blocky toy houses, which `ASSETS.md` rule 5
  says read wrong. Plan: (1) `generate_mesh` each house type from a precise prompt (1990s north-central Vietnamese
  rural house: one storey, ochre lime-plaster walls, red terracotta tile roof, wooden shutters, a front porch on
  wooden posts, a brick yard) and the props around it; (2) use store models only for small props (water jars, nón lá,
  baskets, bamboo, dock); (3) if that's still not good enough, a paid pack or a commissioned modeller (Catlyn's call).
- **Pipeline (2026-11-02):** `docs/MESHY.md`. Meshy's free plan makes the house kit (roof, walls, porch: separate
  meshes so each takes its own Roblox material) plus the shrine, lantern, altar, boat and puppet pavilion; waiting on
  Catlyn to generate them (W-06).
- **Done when:** every house reads as a Vietnamese village house up close (porch, roof tiles, shutters, yard
  clutter), Catlyn approves screenshots, names/tags/positions kept, `test.py --art` PASS, assets logged.

### I-11 · Characters look bad
- **Needs:** no Studio to choose the looks and write the code; Studio to see them.
- **What Catlyn saw:** "the modeling of the characters was very bad". All of them: Bà Thu, Bin, Sen, the lost
  children (today Sen and the children are blocks in `Shared/Figures.luau`).
- **Plan:** real R15 rigs built in code from a HumanoidDescription (catalog hair, clothes, hats, faces: works in any
  place without owning the items), so they animate and match the players' avatars. Looks from `characters.md`:
  Bà Thu small and bent, gray bun, worn áo bà ba; Bin bright jacket, headlamp, camcorder; Sen small, thin, faded
  soaked áo bà ba, long tangled hair over her face, one plastic sandal; children dark silhouettes. Store NPC models
  only where much better (e.g. "grandma" 137203388093234, a realistic Asian grandmother; her bag looks branded and
  must go). Avoid anything that reads as Sadako / The Ring for Sen.
- **Done when:** each character in a screenshot reads as described in `characters.md`, Catlyn approves, Sen's face
  stays hidden, `test.py` PASS.

### I-12 · Cinematic first person: see your own arms, and others see your poses
- **Needs:** Studio to test and tune (angles, camera offset, bob).
- **What Catlyn asked:** players locked in first person, able to see their own arms and hands; when they hold their
  hands up (camera, flashlight) they see it and other players see it too.
- **Built (branch `playtest-fixes`, not tested):** `Controllers/BodyController.luau` + `Services/BodyService.luau`.
  Locked first person in a run, camera a little forward of the head (`Config.FirstPersonCameraOffset`), own body
  visible except head and hat/hair, hidden while looking through the viewfinder. Everyone holds a visible camcorder
  prop in the right hand (REC light glows when raised). Heads and waists follow where each player looks
  (`LookPitch`, 8 times a second); with the camcorder up both arms rise to the eye; all players see all poses (R15).
  Head bob, breathing, a lean when strafing. The mouse is freed while a panel needs clicks. `tests/11_body.luau`.
- **Open question:** there is no flashlight in the game (only the camcorder; Bin's headlamp is his). Adding one is a
  design change (how dark the village is): Catlyn's call.
- **Done when:** in Studio the body reads right in first person (no clipping into the torso when looking down), a
  second test client sees the arms come up with the camcorder, panels are clickable, `test.py` PASS.

### I-13 · Music: intense and eerie
- **Needs:** someone to listen (W-01); Studio to hear it in place.
- **What Catlyn asked:** music designed for fast-paced, intense games, and eerie music.
- **Built (not listened to):** a music layer in `SoundController`, crossfaded: the menu (a dark music box), a quiet
  drone bed in the open village, tension from Sen's 2nd warning, a chase from her 4th, fading back 9 s after the last
  step; silent when taken, in the finale (it has its own) and in Im lặng. Tracks are licensed (APM, DistroKid
  verified uploads) and chosen by name/length; alternatives in `ASSETS.md`.
- **Done when:** Catlyn has listened and approved or swapped each of the four (`Content/Sounds.luau` `music_*`).

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
- **W-06 · Meshy, November's ten** (`docs/MESHY.md`): generate the ten queued in `art/meshy/manifest.json` on the
  free plan (two Lite previews each, mesh only, download the better as `.glb` into `art/meshy/in/<name>.glb`), and
  make an Open Cloud key for `upload.luau` (or use Studio's 3D Importer). Then Claude checks, uploads and places them.

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
