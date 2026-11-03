# Release readiness: Làng Vọng (Mada), 2026-11-03

The owner (Noptable) played the published game (version 3, main 6434eba) and says it is still bad ("still ass") and
wants it turned into a fully running game. You are one reviewer of the factory's Scene Review + Release Council.

**The game:** a 1-4 player co-op horror game in a Vietnamese lake village at night (story: docs/PROTOTYPE_BRIEF.md,
docs/VILLAGE.md, src/shared/Content/*.luau). A team joins from a menu, arrives, finds Bin, the Night 1 scripted beats
play (tapes on a camcorder), then the Open phase: explore houses for clues and the lost children's mementos, avoid Sen
in the water (warnings, then she takes a lone player near the water), light lanterns, give Sen her letter and write
her name for the good ending (Về nhà), or everyone is taken (Im lặng). Work list: docs/ISSUES.md.

**Inputs:** the repo at C:\Users\GIGABYTE\mada (code in src/, tests in tests/), the test report and every screenshot in
C:\Users\GIGABYTE\mada\docs\council\2026-11-03-release-readiness\shots (report.md + 27 .png, taken in Studio at test
speed; a few frames are mid-transition test artifacts: say so when unsure).

**The bar:** a published, popular Roblox horror game of the same kind (e.g. the best-rated short co-op horror stories).
Not "fine for a prototype". Score what you review 1-10 and be specific.

**Output (markdown, under 600 words):** your score, then a numbered list of the problems that keep this from being a
fully running, good game, most important first. For each: what is wrong (with the file:line or the screenshot name),
why it matters to a player, and the concrete fix. Mark each **BUG** (broken, can be fixed without changing the design)
or **DESIGN** (needs the owner's approval: a change to what the game is). No praise paragraphs.
