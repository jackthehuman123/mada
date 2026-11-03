# Brief: Scene Review round 2 + Release Council, Làng Vọng (Mada), 2026-11-04

**What this is:** the build after the 2026-11-03 release-readiness council (verdict FIX FIRST, Player 3/10, Art 4/10,
Engineer 4/10, Plumber 3/10 art · 5/10 UI). Everything in its verdict was done in five commits on `main`:
- 34d9886 live-server bugs (menu sync, teleport recovery, guarded startup, late letter, rate limits, window flicker)
- d55d97e look and legibility (message backing, ending text, camcorder look, paper lanterns, shrine lacquer, room lamps,
  camera keys)
- ba69141 gameplay (goal line + counts, rules taught in play, Sen walks out of the water after a lone player, solo way
  back from the drowned festival, recap then back to the menu, dialogue skip, shorter lantern drift, a scare on the lane)
- f38cfb6 Blender art (13 own models: Sen, a lost child, her face and hand, the shrine + altar, paper lanterns, reeds,
  causeway, sampan, fences, fish racks, well)
- 41a7edd + cc6c7b2 from the first bot playthrough: long hair no longer fills the first-person view; the recap replaces
  the ending card instead of sitting on it

**The game:** a 1-4 player story horror game. A YouTube team visits Làng Vọng at night. Their friend Bin vanishes; the
ma da Sen (a drowned girl) takes anyone alone by the water. The team searches four lantern-lit houses and Sen's house
for clues, finds a letter, gives it to Bà Thu, and at midnight gets Về nhà (good ending) or Im lặng (bad).

**Inputs:**
- Test report + screenshots: `tools/factory/reports/<latest>/` (report.md and *.png)
- Playthrough: `tools/factory/reports/playthrough-<latest>/` (timeline.md, shots/, sheets/, inspector.md)
- Round 1: `docs/council/2026-11-03-release-readiness/` (round1-*.md, verdict.md)

**Bar (factory rule):** a published, popular Roblox horror game. Art Director 8+ ships, nothing under 7. Test artifacts
(the intro card left up by a debug phase jump, debug panels, mid-fade frames) are not defects: say so and move on.
**Publish here means group-only:** the closed-playtest gate stays on (only Raumania members can join).
