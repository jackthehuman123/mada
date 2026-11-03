# Verdict: release readiness, Làng Vọng (Mada) version 3, 2026-11-03

Chair: Claude (factory session). Reviewers: Art Director 4/10, Player 3/10, Engineer 4/10 (live), Plumber art 3/10 and
UI legibility 5/10. Rounds: round1-art.md, round1-player.md, round1-engineer.md, round1-plumber.md.

**Verdict: FIX FIRST.** The story and the night mood work. As a game it fails three ways at once:
- a new team doesn't know what to do or what threatens them
- the things they look at (shrine, Sen, the children, the face) are placeholder blocks
- several live-server paths (the menu, teleports, a solo run, errors) can leave a player stuck

## A. Bugs: fixed now (no approval needed)
1. The menu doesn't sync for a newcomer: the client asks for the state once it is connected (Engineer 1).
2. A failed teleport strands the team: the player list is rebuilt on each try; on failure `starting` clears and the team is told (Engineer 2, 8).
3. One controller error blacks out the game: each Init/Start is guarded; the Sen scene always restores the camera and the HUD (Engineer 6).
4. A late letter loses the good ending: if the name is written, Bà Thu goes to the steps and Về nhà plays (Engineer 7).
5. A late arrival waits forever: the run begins for whoever arrives (Engineer 9).
6. Unthrottled remotes: Track and MenuAction get a per-player rate limit (Engineer 10).
7. Overlapping hints can leave a window stuck dark or neon: the original look is restored (Engineer 12).
8. Text unreadable on dark frames: messages get a dark backing bar and brighter text, and the ending text waits for the fade (Plumber 8).
9. Camcorder view: the Journal button hides under the viewfinder, the tint is darkened, and there is a minimum exposure so tapes are never black (Plumber 4, Art 4).
10. Lanterns render as flat neon blobs: dimmer neon plus a soft light (Plumber 3).
11. Shrine reads as saturated plastic: lacquer maroon, a smaller offering (Plumber 2, Art 1, colour part only).
12. Interiors go black: a warm light in each house (Art 4).
13. The camcorder controls are never shown: a key hint when the camera is picked up (Player 8).

## B. Design: needs the owner's yes (proposal, ranked)
1. **A goal chain on screen.** After "Find Bin.", every beat points to the next ("Bin's tape shows the carp steps", "Ask Bà Thu about the letter"), with a counter for the clues and mementos (Player 1, 6).
2. **Teach the rules in play.** Night 1 shows the three rules through Bin's tape and Bà Thu's lines, once each: stay together away from the water; the shrine is safe; incense brings the taken back. The incense count goes on the HUD (Player 2).
3. **A threat you can see coming.** Sen leaves the water after the third warning and walks toward a lone player (slow, visible, a sound), so it's a chase, not a time-out (Player 4).
4. **Solo is playable.** Alone, the first taking sends you to the drowned festival with a way back (light the lantern and reach the shrine), and the second is for good (Engineer 4).
5. **A run ends properly.** After an ending, a recap card (clues found, mementos, who was taken), then the team goes back to the menu (Engineer 3, Player 7).
6. **Cut dead time.** Bà Thu's lines can be skipped as a whole, the lantern drift is shortened, and the long lane gets one scripted scare (Player 3).
7. **Art pass in Blender (the main work):** Sen (áo bà ba, long wet hair), the lost children, the jumpscare face, her hand, the shrine (eaves, carved posts, an altar with an incense bowl and a framed photo), paper lanterns, reeds, a mossy causeway, village props (fish racks, a boat, fences, a well). The same function signatures, so the tests stay (Art 1-3, 6-8, Plumber 5-7).
8. **Release config:** the closed-playtest gate (group 5099606) goes to 0 the day the game is public. That's your call.

## C. Artifacts, not bugs
- The magenta frame in `06_night1-dialogue` is the test teleporting onto the shrine spot, inside a lotus lantern.
- Several black frames are mid-fade.
- The letter panel open on three shots is the test reusing it.
