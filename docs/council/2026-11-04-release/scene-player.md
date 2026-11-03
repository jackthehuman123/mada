# Scene Review round 2 - Player (13-17, Doors / Mimic / Apeirophobia fan)

**Score: 6/10 (round 1: 3/10).** I now stay past minute 10 and finish the story. I would not yet tell friends. I quit around minute 5-7 if I get taken, or minute 10-12 if solo and nothing chases me.

| # | Round-1 complaint | Now | Evidence |
|---|---|---|---|
| 1 | No objective | FIXED | Goal line on screen the whole run: "walk with Bin to the shrine", "Find Bin. Search the houses the lanterns lit.", "Who was the girl on Bin's tape? Try the house at the end of the lane.", "bring the letter to Bà Thu". Timeline ticks 7 and 11 pass. |
| 2 | Rules never taught | MOSTLY FIXED | Subtitle at 87 s "Bà Thu's rule: she takes the ones who are alone by the water. Stay together..." and "You carry two sticks of incense (pick one from your hotbar and click)". Counter "Clues 0/14 - Mementos 0/4 - Incense 2". But the incense text sits over the screen while I walk away from the shrine (frames 92-100 s) and the camera keys are not visible in the shots I opened (only the "Journal (J)" button). |
| 3 | Dead time | PARTLY | Dialogue now has Skip (tick passes). Lantern drift is ~10 s. But Open phase starts at 78 s and the first clue panel only after 90 s, so that is fine. The lane walk is still a dark empty field (frames 95-111 s, almost black). |
| 4 | Not scary / no land threat | PARTLY | There is now a cry from the water and "[small wet footsteps, close behind you]" (228 s). Good beat. But I never SEE Sen in the frames: 226-230 s is lake and a dark wall, then a blue screen. Being taken is a blue fade. |
| 5 | Art looks like toys | BETTER | Shrine (02_world-shrine, 11_art-sen-child) has a roof, lanterns, altar, glow: reads as a place now. Sen has long dark hair and a dress. Still the shrine in 02_world-shrine has a flat black roof slab (the shot before the model swap?) - mixed. Houses are still plain orange boxes (190 s). |
| 6 | Clue chain invisible | FIXED | Counter + goal switches to Sen's house after 4 clues. |
| 7 | Thin reward / replay | PARTLY | Recap now lists the letter and clues (13-recap). No unlock/score I can chase. |
| 8 | Controls undiscovered | NOT CHECKED / LIKELY OPEN | Only "Journal (J)" visible bottom-left. Brief says "camera keys" hint exists; I did not see it in the sheets. |
| 9 | Intro card | n/a (test artifact) | |

## What still loses me (ordered)

1. **The taken state is 180 s of nothing (DESIGN/BUG).** Timeline: taken 232 s, back on the shore 424 s. Sheets 10 and 14 (262-392 s) are the same dark frame: five silhouettes, a stage, and one orange button "Light a lantern (3)". Text says "Nobody is coming for you." That is a time-out. The bot step timed out at 200 s. I am not sure whether a real player needs 3 clicks or a wait; either way no progress feedback is shown and the stuck hint only fires at 301 s. Fix: shorten to ~30-45 s, show the button count going down, add a sound or a figure that moves. If solo players take a lot of time here, I leave.
2. **I never see Sen (DESIGN).** Warnings 1-5 take 10 s (222-232 s) and the screen cuts to blue. The brief promises she walks out of the water; in the 226-230 s frames the shore is empty. Fix: hold on her silhouette for the last 2 warnings, add camera turn toward the water.
3. **First-person has a giant purple "R" shirt filling the view (BUG).** Frames at 90-94 s: a purple torso with a Roblox "R" logo covers half the screen. It looks like the default avatar torso, not the horror look. Commit 41a7edd fixed hair, not this. Fix: hide the torso/arms in first person or drop the shirt graphic.
4. **Lane is almost black (DESIGN).** 95-111 s: I can see the shrine glow and nothing else. With a 13-year-old's screen brightness I would think it's broken. Fix: a faint path of lanterns or moonlight on the grass.
5. **Houses and people still look like blocks (DESIGN).** 190 s: an orange wall and a red blocky NPC. Not scary, but acceptable for a Roblox horror if the dark hides it.
6. **Recap goes to the menu, but the bot step 14 timed out (90 s).** Studio-only artifact per the brief (run server sends the team to the menu); I count it as not a defect.
7. **Three bot ticks failed (pickup hold, altar hold, step 9 timeout).** Each was passed by a debug fallback. If the pickup or altar prompt needs a hold that doesn't register, I'd be stuck; check the hold time is not longer than the on-screen prompt suggests (BUG, unconfirmed).

## Would I tell friends?
Not yet. The story and goal line now work. For "popular Roblox horror" I need a visible Sen, no 3-minute dark limbo, and no purple shirt in my face. Fix those three and I'd say 7-8.

Files: C:\Users\GIGABYTE\mada\tools\factory\reports\playthrough-20261104-022146\sheets\sheet-03.jpg, sheet-08.jpg, sheet-10.jpg, sheet-14.jpg; C:\Users\GIGABYTE\mada\tools\factory\reports\20261104-021813\08_sen-drowned-festival.png, 11_art-sen-child.png.
