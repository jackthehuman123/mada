# Làng Vọng — Prototype Brief

The build spec for the first playable prototype. Design intent lives in `docs/design/`; this file turns it into rules, numbers and checks. Where the design docs say "to discuss", this brief picks a **default** (listed in §12) so building can start. Catlyn can overrule any default; log changes in `DECISIONS.md`.

---

## 1. Goal and hypothesis

**We believe** that a co-op mystery where progress comes only from *understanding* — clues spread across houses, plus a camcorder that shows what eyes can't — wrapped in Vietnamese ghost-month folklore, will lead groups of 2–4 players who don't know the story to work it out and reach the true ending, and that it will feel frightening without gore.

**This prototype exists to test that.** It is built for playtests, not release. Success looks like:

- At least half of first-time groups find Sen's house and the letter without being told where to look.
- At least a third reach the true ending (*Về nhà*) in one run of 45–60 minutes.
- Playtesters react to the Bà Thu camera reveal (we'll watch for it).
- Nobody gets stuck for more than ~5 minutes without a hint firing.

## 2. Non-goals (do NOT build these)

- Monetization, shop, game passes, ads.
- DataStore saves, progression between runs, badges, leaderboards.
- Lobby, matchmaking or party UI beyond "players join the server, game starts".
- Voice acting and voiced cut scenes (text + sound only). The teller's narration appears as on-screen text cards.
- Vietnamese localization (but keep all strings in `Content/` so it's easy later).
- Chapters / the release-plan split. Build one continuous run.
- Player roles (host, researcher, sound, camera) — players use their own avatars.
- Hungry ghosts (*cô hồn*), rice and salt.
- The *Ở lại (Stay)* ending — cut (Catlyn, 2026-11-02): the endings are Về nhà or Im lặng.
- The Quiet Man / Silence threat — optional M8; left out for now (Catlyn, 2026-11-02), revisit after the first playtest.
- Final art. Graybox is fine until M7.
- Mobile-specific UI tuning. Desktop first, but use ProximityPrompts and on-screen buttons so mobile isn't broken.

## 3. Structure of one run

Default shape: **one continuous night** (from `timeline.md` option 1). All times are in `Config.luau`.

| Phase | In-game time | Real time (default) | What happens |
| --- | --- | --- | --- |
| `Intro` | — | ~30 s | Text card: the rumor video the channel watched ("in Làng Vọng, the lanterns light themselves"). |
| `Arrival` | 18:30 dusk | until players reach the shrine | Spawn at the village end of the causeway with Bin (NPC). Shrine lanterns glow as the only wayfinding. |
| `Night1` | 19:00 → 21:00 | ~8–10 min, scripted | Same every time. See §4. |
| `Open` | 21:00 → 24:00 | 35 min | Free exploration. Clock visible on the camcorder HUD only. Threats active. |
| `Finale` | 24:00 | 2–4 min | Ending decided by what players did (§7). |
| `Ending` | dawn | ~1 min | Text card from the teller + short scene. Then the server resets after 30 s. |

## 4. Night 1 (scripted beats)

A `NightOneDirector` service runs these beats in order. Each beat logs `[Night1] beat N` to the console and waits for its trigger.

1. **Arrival.** Players spawn at the causeway end. Bin walks with them (simple follow/pathfinding). Trigger: any player enters `ShrineZone`.
2. **Bà Thu at the shrine.** She sits among lanterns, folding. Dialogue (players advance it): welcome and tea; the children the lake took (Minh, Hạnh, Tí, Khoa); the old festival; then, almost to herself, the bedtime story (*the lanterns carry the lost souls across the lake to a happier place, and the carp swim beside them to show the way*); finally "My daughter's staying with relatives. She'll be home soon." Bin films the whole scene (this becomes Tape 1).
3. **Lanterns.** Bà Thu sets four lanterns on the water. Each drifts along its `LanternPath` (~60–90 s) to the shore below one lost child's house; when it arrives, that house's window lights up and a faint child's sound plays inside. **Sen's house, at the end of the lane, stays dark.** No UI comment on this.
4. **Bin wanders off.** He says he wants a shot of the water and walks east along the shore. When no player has line of sight to him (or after 20 s), he vanishes. A child crying is heard from the water.
5. **Trapped.** The causeway is flooded (water over it, invisible wall, message: "The causeway is under water."). Any path out of the village brings players back to the lake shore (boundary teleport with a fade).
6. **Bin's camera.** Found floating in the reeds near the shrine (`BinCamera` prompt). Picking it up gives the group **Bin's tapes** (§5.3).
7. **Open phase begins.** One line of text: "Find Bin." Nothing else tells players what to do.

## 5. Core systems

### 5.1 Interaction, clues and the journal

- Any object tagged `Clue` with attribute `ClueId` gets a ProximityPrompt ("Look", hold 0.5 s).
- Inspecting opens a panel with the clue's text (and an optional image), from `Content/Clues.luau`.
- Found clues are **shared by the whole group** (server keeps the set) and appear in a journal (key `J`, plus an on-screen button), grouped by place.
- **No counters, no checklists, no "2 of 4".** The journal is a scrapbook, not a progress bar.
- Every house contains a clue that points to another place (see §6). Players move because clues pull them.
- **Mementos** (one per lost child's house, tag `Memento`): picking one up plays a short memory of that child's last day — prototype version: screen fades, 2–4 lines of text, a sound, fade back.

### 5.2 The camcorder

Every player has a camcorder Tool (the channel's gear).

| Action | Default input | Rule |
| --- | --- | --- |
| Raise / lower viewfinder | Right mouse or `F` | VHS overlay UI, FOV 55, time + battery shown. Drains the battery (300 s of use from full, see below). |
| Record | `R` while raised | Records a clip (max 20 s). Max 3 clips per camcorder; oldest is overwritten. |
| Play back | `T` → choose a clip | Watch a clip in full screen with the VHS overlay. Player can't move while watching; `T` again exits. |

- **Battery:** 300 s of viewfinder time. Recharges at the shrine (+5 %/s while inside `ShrineZone`). At 0 % the viewfinder and playback are off.
- **Live viewfinder:** shows objects tagged `CameraOnly` (Sen's wet footprints, drowned children standing in the water) that eyes can't see. Bà Thu **does** appear in the live viewfinder.
- **Playback:** also shows `CameraOnly` objects, and **hides everything tagged `HiddenOnCamera`** (Bà Thu, her lantern-folding hands, her tea being poured). Players see themselves talking to an empty mat and drinking from dusty cups.
- **How recording works (prototype):** sample the camera CFrame at 10 Hz, and log any `CameraOnly` ghost events in view (template id + CFrame + time). Playback moves a scriptable camera along the recorded path through the *current* world, spawns local copies of the logged ghost events at the right times, and hides `HiddenOnCamera` locally. Other players appear where they are now, not where they were — acceptable for a prototype; note it in `DECISIONS.md`.
- Visibility tricks are **local only** (client-side transparency changes); the server never hides Bà Thu.

### 5.3 Bin's tapes

Picking up Bin's camera adds two authored clips, playable by anyone, from a "Bin's tapes" list:

- **Tape 1 — the shrine:** the Night 1 shrine scene from Bin's angle. Bà Thu is not in it (played back with `HiddenOnCamera` hidden).
- **Tape 2 — the steps:** a handheld path down a set of stone steps into dark water; at the bottom, a small girl standing in the water, looking up. Ends in static. The steps are the **carp steps** behind Sen's house, but nothing says so.

The tapes are authored as recorded CFrame paths + ghost events in `Content/Tapes.luau`, played through the same playback code.

### 5.4 Lanterns and hints

- On Night 1 (and again at 23:00 as a repeat, so players can watch a second time), four lanterns drift from the shrine to the shore below each lost child's house and light its window. Never to Sen's house.
- **Stuck hint:** if the group finds no new clue for `Config.HintAfterSeconds` (240 s), the window of the nearest house that still has unfound clues flickers, and a lantern on the water near it pulses. A taken player can trigger the same flicker (§5.6).
- Bà Thu can be talked to again at any time; she repeats her stories with one new detail per repeat (lines in `Content/Dialogue.luau`).

### 5.5 Sen (the ma da)

Active only in the `Open` phase. Never inside `ShrineZone`.

- Every 60–120 s the server picks a target: a player who is **alone** (no other player within 25 studs) and **within 30 studs of water** (`WaterEdge` tag). If nobody qualifies, she waits.
- **Warning ramp** on the target (each step ~5 s, cancelled if the condition breaks):
  1. A child crying from the water (positional sound).
  2. Carp gather at the edge nearest the player.
  3. Small wet footprints appear behind the player (`CameraOnly` — only seen through the viewfinder).
  4. Humming of a children's tune; subtitle shows the tune with the player's display name in it.
  5. **Taken** if they're still alone and near water.
- **Counters:** get back within 25 studs of another player; step away from water; enter the shrine; or use **incense** (each player carries 2; using it makes Sen withdraw from that player for 60 s).
- She is seen only as a reflection, a shape among the carp, or a lantern moving against the wind. In the prototype she never chases on land.

### 5.6 Taken and rescue

- A taken player fades out and wakes in the **drowned festival**: a separate space far below the lake (e.g. Y = −400), dim lights, rows of children's silhouettes (Minh, Hạnh, Tí, Khoa, and Bin) watching a puppet show that never ends. Nothing attacks them.
- From there they can press **"Light a lantern"** (once per 60 s) to make a lantern flicker on the surface near the nearest unfound clue — visible to their friends.
- **Rescue:** teammates light incense at the shrine altar (`ShrineAltar` prompt, hold 3 s). The taken player returns at the shrine. Each player can be rescued **once per night**; a second taking keeps them below until the ending.
- If every player is taken, the run goes straight to the *Im lặng* ending.

### 5.7 The letter and the true ending

- **The letter** is hidden under the family altar in Sen's house (prompt "Look under the altar", hold 1.5 s). It's a carried item — one per run; whoever holds it can drop it or hand it on. If a holder is taken, it drops where they stood.
- **Giving it to Bà Thu** (talk to her while holding it): the players read it out (*Sen never came here. Where is she?*). She stops smiling and cries. She takes out the half-finished paper fish, finishes it, and asks the players to write the name on it — a button **"Write: Sen"**. The first time that name is written anywhere in Làng Vọng.
- Bà Thu then walks (pathfinding) through the lane to her own house, through the back yard, to the **carp steps**. Players follow. When she reaches the bottom step, the clock jumps to midnight and the finale plays (§7).
- Players don't need any clue except the letter for this to work mechanically. Understanding is what gets them there.

## 6. Content: the places and what they hold

Clue texts are written by the agent as **drafts** from `story.md` and `gameplay.md` (mark `-- DRAFT`), in `Content/Clues.luau`. Use only facts in the story. The required clues:

| Place | Tag `Location=` | Clues (ClueId → what it shows) | Points to | Memento |
| --- | --- | --- | --- | --- |
| Shrine | `Shrine` | `shrine_redpaper` → the red paper list of lost children for the shrine, copied names; Sen's name is not on it. `shrine_photos` → a photo for every lost child except one. | the four houses | — |
| Teacher's house | `TeacherHouse` | `teacher_classphoto` → class photo, skinny girl at the end of the row, hair in her eyes, not smiling, labeled *Sen*. `teacher_report` → his unsent report: something wrong in that house; her father keeps the family away from festivals. `minh_notebook` → Minh's notebook mentions his friend Hạnh. | Sen's house; puppet master's | Report card with one red mark |
| Puppet master's house | `PuppetHouse` | `puppet_diary` → the night of the festival, one lantern drifted out from behind the last house on the lane; "that's strange", and he said nothing. | Sen's house, and behind it | Broken water puppet |
| Fish seller's house | `FishHouse` | `fish_notes` → a letter from the city she handed Sen's father; his face went the color of ash; "Don't mention this to Thu." | Sen's house (the letter) | Clay whistle |
| Village head's house | `HeadHouse` | `head_minutes` → minutes of the vote to leave; "What about Thu's girl?" — *Told to sit down.* `head_redpaper_draft` → his draft of the shrine list, no Sen. | Shrine; teacher | Festival drumstick |
| Sen's house (never locked, always dark) | `SenHouse` | `sen_doorframe` → no height marks on the doorframe. `sen_bowl` → one small bowl and chopsticks, freshly washed. `sen_chair` → an old woman's chair facing the door; teacups gray with dust (the same cups from the shrine). `sen_fishlantern` → a half-finished paper fish lantern on the shelf. `sen_altar` → **the letter** (item). | The back yard → carp steps | — |
| Carp steps | `CarpSteps` | `steps_sandals` → little sandals lined up, one pair for each lost child. Carp rise when players climb down. | — | — |

Players who enter Sen's house early just find a sad, ordinary home. That's intended.

## 7. Endings

| Ending | Trigger at midnight | Prototype presentation |
| --- | --- | --- |
| ***Về nhà* (Going home)** — true | Bà Thu was given the letter, the name was written, and she reached the carp steps. | The fish lantern drifts to the middle of the lake. Sen rises holding hands with Minh, Hạnh, Tí, Khoa and Bin. Bà Thu walks onto the water and takes her hand. Hundreds of carp; lanterns carried across the lake; fade. Dawn: causeway dry, Bin wakes on the bank. Teller's text card. |
| ***Im lặng* (Silence)** — tragic | Anything else at midnight (or every player taken). | Every lantern on the lake goes out at once; Sen takes the players still free one by one; all sound dies; fade to static and faint festival music. Teller's text card. |
| *Ở lại (Stay)* | Cut (Catlyn, 2026-11-02). | — |

Ending texts: adapt from `story.md` §15 and §16 as drafts.

## 8. Map (text stand-in)

The design doc's map image didn't export. Use this layout until Catlyn adds `docs/design/map.png`. Distances are starting points; tune for walking time (lane end to end ≈ 60 s of walking).

```
                         FAR SHORE (visible, not reachable)
                    [Puppet stage on the water]   festival lights
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ~~~~~~~~~~~~~~~~~~~~~~~~~~  THE LAKE  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ~~~~~~~~~~~~~~~  (*) lantern gathering point, middle of lake ~~~~~~~~~
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ~~ shore ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ [cove] ~~~~
   [SHRINE]  [DOCK]   reeds                                  carp steps
      |        |                                                 ^ (only via back yard)
  ====LANE (dirt path along the shore, west -> east)==========================
   [Communal] [Head] [Fish] [Puppet] [Teacher] [ ] [Teller's old] [ ] [ ] [SEN]
     house    (Khoa)  (Tí)   (Hạnh)   (Minh)                              end of lane
  ====
   |
  CAUSEWAY over the marsh (southwest) -> flooded after Night 1
  spawn at its village end
```

- **Lake:** ~600 × 400 studs, Terrain water. Lantern gathering point in the middle.
- **Village:** on the near (south) shore, one lane parallel to the water, houses on the inland side, small yards to the shore. Each lost child's house has a `LanternStop` on the shore below it.
- **Sen's house:** last house at the east end of the lane. Behind it, the back yard leads through bamboo and rocks to the **cove** and the **carp steps**. The steps can't be seen or reached from anywhere else; from the bottom step you see the whole lake to the far shore.
- **Teller's old house:** three doors down from Sen's (empty, a few filler clues allowed only from the story).
- **Shrine:** west end, by the water. Safe zone (`ShrineZone`).
- **Dock:** small wooden jetty near the fish seller's house.
- **Causeway:** long raised path southwest over marsh; flooded after Night 1.
- **Far shore + puppet stage:** visible across the water as lights; not reachable.
- **Drowned festival:** separate space at Y ≈ −400 (§5.6).
- Setting: 1990s north-central Vietnamese village — tile and thatch roofs, bamboo, banana trees, water jars, family altars, paper lanterns, lotus and reeds. Night, mist, warm lantern light against cold blue.

## 9. Systems, in build order

1. **Bootstrap** — server Services / client Controllers loader, `Remotes`, `Config`, `Tags`, `DebugService`. (scaffolded)
2. **GameState** — phase machine (§3), game clock, lighting per phase, reset.
3. **World graybox** — `tools/worldgen/` scripts that build §8 from parts + terrain and tag everything.
4. **Interaction + clues + journal** (§5.1).
5. **Dialogue** — linear lines with "next", a few branches by held item / flags (Bà Thu, Bin).
6. **Camcorder** — viewfinder, record, playback, battery, local visibility (§5.2).
7. **Lanterns** — drift paths, window lights, hint flicker (§5.4).
8. **Night 1 director** (§4) + Bin's tapes (§5.3).
9. **House content** — all clues and mementos (§6).
10. **Sen + taken/rescue + incense** (§5.5, §5.6).
11. **Letter + true-ending sequence + endings + midnight** (§5.7, §7).
12. **Art and audio pass** (assets).
13. **Playtest instrumentation** (§10).

## 10. Analytics (stub)

One module `Shared/Analytics.luau` with `track(name, data)` that prints `[Analytics] name {data}` and keeps an in-memory list (swap for Roblox `AnalyticsService` later). Events:

`session_start`, `phase_change`, `clue_found {clueId, t}`, `memento_viewed`, `camera_record`, `camera_playback {clip}`, `bin_tape_played {tape}`, `hint_fired {house}`, `sen_warning {step}`, `player_taken`, `player_rescued`, `letter_found {t}`, `letter_given {t}`, `ending {type, t}`, `session_end`.

At ending, print a one-line summary (time to each key event) so playtest sessions can be compared.

## 11. Milestones and acceptance checks

Each milestone must be demonstrable by the agent through MCP (playtest + console + screen capture + debug commands). Stop points marked ★ are playable on their own.

| # | Milestone | Acceptance check |
| --- | --- | --- |
| **M0** | Toolchain | `rojo serve` syncing; MCP connected; playtest prints `[LangVong] server started` and `[LangVong] client started` with no errors. |
| **M1** | Graybox village | Every place in §8 exists and is tagged with its `Location`; night lighting; boundaries work. `character_navigation` from spawn reaches each `Location` (log which). Top-down and lane-level `screen_capture`s described in PROGRESS. |
| **M2** | Core tools | Clue prompt → panel → journal works with 2 test clues. Camcorder: a test dummy tagged `HiddenOnCamera` is visible live but absent in playback; a test object tagged `CameraOnly` is invisible to eyes, visible in viewfinder and playback. Battery drains and recharges in `ShrineZone`. |
| **M3 ★** | Night 1 | A playtest runs beats 1–7 unaided (Bà Thu dialogue, 4 lanterns arrive and light 4 windows, Sen's house dark, Bin vanishes, causeway flooded, Bin's camera with both tapes). Console shows `[Night1] beat 1..7`. Ends in `Open` phase. *This is the "Chapter 1 teaser" stop point.* |
| **M4** | Mystery content | All clues and mementos in §6 placed and readable; every house points to another; the letter can be picked up. Debug-walk to each clue logs `clue_found` for all. Hint flicker fires after 240 s idle. |
| **M5** | Sen + taken | With one player alone at the water: warning steps 1–5 fire in order, then taken → drowned festival. Rescue via shrine incense returns them. Incense makes her withdraw. Shrine is safe. |
| **M6 ★** | Endings | Debug clock to 23:50. Path A: give letter → write name → Bà Thu walks to the steps → *Về nhà* plays. Path B: do nothing → *Im lặng* at midnight. Server resets afterwards. *Full run playable start to finish.* |
| **M7** | Art + audio | Graybox replaced with sanitized free assets / generated meshes, all logged in `ASSETS.md`; ambient night sound, water, radio static, distant festival drums at the finale. No scripts inside inserted assets (check with `search_game_tree` for Script classes under `Workspace.World`). Client stays smooth on the dev machine. |
| **M8** | Playtest build | Analytics summary prints at the end. Optional extra, left out for now (Catlyn, 2026-11-02): the Quiet Man/Silence zone in Sen's house (hide-only, radio warning, caught → wake at the gate). Human publishes a private test place. |

## 12. Open questions and defaults

These come from the "Questions to discuss" sections of the design docs. Build with the default; Catlyn decides later.

| Question | Default for the prototype |
| --- | --- |
| Timeline shape (one night / night-day-night / rest skips time) | One continuous night with a clock. Lanterns drift twice (Night 1 and 23:00). |
| How long should a run take? | 45–60 minutes. |
| Players' own avatars or designed characters? | Own avatars. |
| Voice acting? | No. Text + sound. |
| How much of Sen's face to show? | None in the prototype. |
| Who owns the camera? | Every player has a camcorder; Bin's camera holds two authored tapes. |
| Does Sen hunt everywhere near water, or only at times? | Only in the `Open` phase, only lone players within 30 studs of water. |
| Which threats are active on Night 1? | None. Night 1 only teaches (crying from the water, Bin's disappearance). |
| Is the father a threat to escape or hide from? | Hide only. Optional in M8. |
| When does the Silence spread? | Not in the prototype (M8 optional: Sen's house only). |
| What if players reach midnight with half the story? | *Im lặng* ending. |
| Which two houses go first (for a Chapter 1 cut)? | Teacher's (gives the name) and fish seller's (points to the letter). Build these first in M4. |
| Ship in chapters or whole? | Not the prototype's question; build one run. |
| UI language | English, with Vietnamese names and terms in full diacritics. |
| Max players | 4 per server. |
| Content maturity | Human fills in Roblox's maturity questionnaire before any public test (horror themes, implied family violence). |
