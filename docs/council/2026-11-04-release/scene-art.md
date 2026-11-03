# Scene Review round 2 - Art Director, Làng Vọng

| Round 1 | Round 2 | Verdict |
|---|---|---|
| 4/10 | **6/10** | Not approved (8+ ships, nothing under 7) |

Scene scores (r1 -> r2): shrine 3 -> 7 (exterior at night) / 6 (close up), lane/village 5 -> 6, causeway 4 -> 4, interiors 5 -> 5, drowned festival 6/2 -> 5 (lanterns 6, figures unjudgeable), Bin/Thu dialogue 2 -> 6, endings 3 -> 5, UI 6 -> 8, camcorder 8.

## Round-1 findings status

| # | Finding | Status | Evidence |
|---|---|---|---|
| 1 | Shrine red slabs | FIXED (mostly) | 11_art-shrine-model, playthrough 13-finale: curved roof, posts, altar with candles, incense, offering, paper lanterns. Still saturated red wood, flat "red rug" panel by the altar, plain granite block with a glowing egg-ball (02-at-shrine). Reads as a shrine now. |
| 2 | Figures box + ball | PARTLY | 11_art-sen-child, 02_world-shrine: the children and Sen now have a silhouette (hair, dress). But they are tiny and dark; 08_sen-drowned-festival shows 5 black cutouts in near-total black (judge from the model shots, not this frame). |
| 3 | Jumpscare face | CANNOT JUDGE | 06_night1-tape2-hand shows a real hand (good: fingers, sleeve), but no frame shows the face at 4-5 studs. 08-lane-scare (playthrough) shows only a palm and a crying subtitle; no figure. |
| 4 | Darkness uneven | PARTLY | Shrine and houses now glow (06_night1-lit-windows style: 02_world-lane houses lit, warm porch). But 02_world-causeway-style frames (11_art-causeway, 11_art-boat, 12_first_person, 08-lane-scare) are still near black with a flat dark-olive ground; 08_sen-drowned-festival is black. |
| 5 | Magenta walls | FIXED | 06_night1-dialogue now shows the shrine, no magenta. |
| 6 | Flat grass, five identical houses | PARTLY | Fences, rack, barrel, window shutters, brick plinths added (02_world-lane). Ground is still one tiling green plane with no paths, mud, crops; houses are still clones. |
| 7 | Reeds + causeway | PARTLY | Reeds are real clusters now (02-at-shrine, right). Causeway (11_art-causeway) is still a black strip on a grey wall block, no moss, no railing. Pier + boat (11_art-boat) are good but too dark to see. |
| 8 | Lantern uniformity | FIXED | Paper lanterns with ribs, glow cone on water (03-lanterns-drift). Drifting flotilla is yellow balls with orange smears: the one weak part (13-finale: big flat yellow ovals). |
| 9 | UI chat hint, subtitle backing | PARTLY | Subtitle backing and goal line are good. **The Roblox chat hint is still visible** in 02_world-lane and 04_camcorder-viewfinder-live (top left, over the viewfinder corner). It is gone in the playthrough shots, so it only shows in the test harness; confirm in a live client. BUG. |
| 10 | Camcorder | KEPT | Good, 13-finale. |

## Ranked blockers to an 8

1. **Outdoor night exposure (BUG, small).** 11_art-causeway, 11_art-boat, 12_first_person, 08-lane-scare and 08_sen-drowned-festival: the player cannot see ground, props or figures. The flat olive grass is the biggest screen area in every outdoor shot. Raise Ambient / fog colour for exteriors and add a cool moon fill so the new models show; in the festival add a rim light on the figures. The Blender work is wasted while it sits in black.
2. **Ground and village sameness (DESIGN).** One tiling grass plane, no worn paths, mud at the water edge, crops, or house variety. 02_world-lane and 13-recap. Add dirt-path strips, a bank-edge texture, 2 house variants.
3. **Interior scale/camera (BUG to verify).** 07-memento-TeacherHouse is a full-screen flat orange wall with a bonsai in the corner (the camera sits in a corner; the wall is unlit orange, no lamp). 07_mystery-sen-house is a grey room with floating shelf and tiny props; no focal light. Interiors still look empty. Add a lamp and 3-4 props per room, and stop the memento framing from facing a bare wall.
4. **Face and Sen unproven (DESIGN to verify).** No screenshot shows Sen's face or a scare at range. Send a shot at 4-5 studs and the one-frame cut. This is the horror's payoff; I cannot grant 8 without it.
5. **Shrine close-up polish (DESIGN, small).** Saturated red wood, flat red rug panel, granite block with a glowing egg (02-at-shrine). Desaturate the red toward lacquer maroon, give the rug a frame, swap the egg for a stone bowl with a flame.
6. **Causeway (DESIGN).** Needs moss, edge stones, railing; it is the story's main route (11_art-causeway).
7. **Lantern flotilla (BUG).** 13-finale yellow ovals reflected as bright slabs; use the paper-lantern mesh at smaller scale with flicker.
8. **Chat hint (BUG).** See above.

## Not defects
Intro card (01), mid-fade frames, debug text, 13-recap panel over a clear sky (a stage, not a bug), the harness label overlays.

## Path to 8
Items 1, 3 and 4 are enough to cross 7. Items 2, 5, 6 and 7 together reach 8. Resubmit with outdoor frames at the village, the causeway, the festival at night and one Sen face frame.
