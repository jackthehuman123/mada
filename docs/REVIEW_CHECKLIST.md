# Review checklist

The reviewer (opus) runs this only for risky diffs: remotes, DataStore, anything trusting the client, or over ~150 lines. Report `file:line: problem`.

- Remotes: the server validates argument types and ranges, checks the player is allowed, and rate-limits.
- No client trust: phase, clock, clues, items, who is taken and endings are decided on the server.
- Connections, loops and tweens are cleaned up (player leaving, reset, scene reload).
- World objects found by tag, not by hard-coded path.
- Public functions have types; `--!strict` at the top of the file.
- Mobile performance: part count, per-frame work, no unbounded loops or spawns.
- Player text is in `Content/` and marked DRAFT when new; numbers are in `Config`.
- Content rules in `docs/GAME.md` hold (no gore, Sen's house implied, father never seen face to face).
- Decisions in the spec's Feedback log ("Decided" lines) are respected.
- Every acceptance check has a test (`[lune]`) or a named playtest step (`[playtest]`).
