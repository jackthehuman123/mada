# Plumber, Scene Review round 2 (33 test frames + 23 playthrough frames viewed)

| Score | Round 1 | Round 2 |
|---|---|---|
| Art | 3/10 | **5/10** (shrine, lanterns, Sen, houses much better; world, water, finale, shoreline not) |
| UI legibility | 5/10 | **7/10** (message backing fixed; Journal panel and fades remain) |

## Round-1 defects: status

| # | Round-1 defect | Status |
|---|---|---|
| 1 | Camera inside Bà Thu in dialogue | **Partly fixed.** 06_night1-dialogue and 03-thu-dialogue now show the shrine, no magenta wall. But Bà Thu is not visible in either frame, only the dialogue box over the altar. Unsure whether she is out of shot or hidden (60%). |
| 2 | Shrine flat red plastic, giant altar box | **Mostly fixed.** Lacquer wood grain, real altar with incense and candles, curved roof, stone plinth (04_camcorder-*, 03-thu-dialogue). Still saturated red under the viewfinder (06_night1-tape1 roof beams). The red-paper banner is a hot red noise texture. |
| 3 | Lantern glow balls | **Fixed for the lantern models** (paper lanterns with ribs, caps, falloff). **Not fixed:** the finale is still 40+ identical flat yellow discs (09_endings-finale-home, 13-finale), and the big "spirit orb" on the plinth is a flat cream ellipsoid. |
| 4 | Camcorder orange wash, HUD over brackets | **Partly fixed.** The chat hint ("Chat '/?'...") still sits inside the top-left bracket in 04_camcorder-viewfinder-live and 04_camcorder-playback. 06_night1-tape1 and 06_night1-tape2 are clean, with a greenish tint on the live view. The sandy floor is still orange in tape1. |
| 5 | Sen as black cube on white box | **Fixed.** 06_night1-tape2 shows a long-haired figure, 06_night1-tape2-hand a pale hand and a head of hair. |
| 6 | Carp steps | **Partly fixed.** Stone steps with posts, but the notch of water is still a straight-edged rectangle and the path is still a pure black strip with a hard edge (02_world-carp-steps). The carp are not visible. |
| 7 | Water and shore edges, palms, flat grass | **Not fixed.** Straight polygon water edges (02_world-carp-steps, 06_night1-flooded-causeway, 11_art-causeway); palms still sticks with plane fronds (08-lane-scare); grass still one tile. |
| 8 | UI text contrast | **Fixed for the bottom message** (dark backing bar, near-white text). Ending text is now readable after a fade (09_endings-ending-home, ending-silence). |
| 9 | Journal panel | **Not fixed.** 03_clues-journal is still a 420x460 beige box with about 15% of it used. |
| 10 | Interior scale | Not testable, no frame with a character in a room. 07_mystery-teacher-house shows a believable wardrobe and bench. |
| 11 | Grey bars | **Resolved.** ending-silence is intentional scanlines with readable text. tape2-hand has content. |

## New or remaining real defects

| # | File | Where | Defect | Sure |
|---|---|---|---|---|
| A | playthrough 05-camera-picked, 05-open-goal-rule | Whole frame | Camera inside geometry: Bin's purple Roblox shirt fills the left third, with a hull-like dark blue mass and reeds filling the view. Near-black, unreadable. Real if a player can stand next to Bin at the reeds. | 75% |
| B | playthrough 10-woke-on-shore | Whole frame | A player "woken on shore" is looking at open water with no shore in sight. The message says "cold grass" but there is none on screen. | 75% |
| C | playthrough 07-memento-TeacherHouse | Left 60% of frame | Camera against a bare orange wall, the clue panel's subject is half off-screen. Wall is saturated flat orange, unlike the dim interior in other houses. | 70% |
| D | playthrough 07-memento-PuppetHouse | Centre | A bonsai in the corner, all walls flat orange, no lighting variation. Reads as a debug fixture. | 60% |
| E | 03_clues-clue-panel | Behind the panel | The red-paper panel hides the object being read; the panel is 520x340 for 3 lines of text with a big blank. | 70% |
| F | 02_world-carp-steps, 11_art-causeway | Right and top edge of water | Straight diagonal water edge against grass with no reeds or mud. The causeway slab is a dark box with no texture. | 85% |
| G | 13-finale, 09_endings-finale-home | Foreground | Water takes a brown swirl texture tinted by lantern light (reads as mud), with sharp cut-out yellow reflection shapes. | 65% |
| H | 08-lane-scare | Right | The palm's fronds are two flat textured planes with a visible cutout edge. | 80% |
| I | 11_art-props | Right of centre | A fence section stands alone and is broken at an angle (reads as a gap, not as intentional). Fences float above the grass with no base contact (about 70%). | 60% |
| J | 02_world-lane | Left | Palm and distant houses are fine, but the grass plane meets the water in a perfectly straight line. | 80% |

## Test artifacts, not defects

- 05_phases-intro-card, 12_first_person-first-person fade state, 01-intro-card, 14-again, 13-ending-card, 06_night1-tape2-under, 02_world-top-down: intro card left up by a debug phase jump, or a mid-fade.
- 07_mystery-* and 03_clues-clue-panel: the same "letter" panel left open across scenes by the test, so the panel text does not match the scene.
- 03_clues-journal: shown on a scene with no props. The panel's emptiness is partly the test, but its size is real.
- 08_sen-drowned-festival: dark stage by design, though the silhouettes are very low contrast (70%).
- 09_endings-write-sen: the intro card overlaid on the dialogue is the debug phase jump.
- 13-recap: daytime sky is probably the intended dawn.

## UI notes

- Message bar and objective panel (top right): readable on every frame, with a dark backing. Good.
- Dialogue box: readable, has a Skip button and "Click or press Enter". Good.
- Journal (J) button: always visible, OK; it overlaps nothing in the live view.
- Chat hint "Chat '/?'..." is the Roblox default, over the viewfinder brackets in 04_camcorder-*. Hide it.
- Letter panel and journal panel are oversized for their content.
