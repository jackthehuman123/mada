@AGENTS.md

# Claude Code notes

- `AGENTS.md` (imported above) is the full instruction set and applies to you. Everything below is Claude-specific.
- The Roblox Studio MCP server is usually registered as `Roblox_Studio`, so its tools appear as `mcp__Roblox_Studio__<tool>` (for example `mcp__Roblox_Studio__execute_luau`). If none appear, run `/mcp` to check status, then follow `docs/MCP_SETUP.md`.
- When the human says "continue" or "begin", start with the start-of-session routine in `AGENTS.md`, then work on the next unchecked task in `docs/PROGRESS.md`.
- Use the task list for the milestone's tasks so the human can see progress.
- For a whole milestone, plan first (list files to create, tags, remotes, test steps), then build. Keep each commit to one coherent step.
- Code goes through normal file edits in `src/`. Use MCP for the world, assets, playtests, console and screenshots, not for editing Rojo-managed scripts.
- Read big design docs with targeted reads when you only need one section; `story.md` is long.

## Running as the GitHub bot

When you run on GitHub (someone wrote `@claude` in an issue or a pull request; set up in `.github/workflows/claude.yml`,
explained in `docs/ASK_CLAUDE.md`):
- There is no Roblox Studio and no MCP. Skip the start-of-session Studio and Rojo checks in `AGENTS.md` §2; read
  `docs/PROGRESS.md` and the files the request is about instead.
- Answer questions in the thread. Make changes only when asked; they go to your own `claude/...` branch. Never merge,
  never push to `main`, never edit `.github/workflows/`.
- `AGENTS.md` still applies in full: no invented story (facts only from `docs/design/story.md`), player-facing text in
  `src/shared/Content/` marked DRAFT and logged in `docs/DECISIONS.md`, no gore, update `docs/PROGRESS.md`.
- You can't playtest or run `tools/factory/test.py`. End every change with what a person must check in Studio
  (and which test, if one exists).
- Keep answers short; one request per run. Work on this repo only.

## Help build the game

Làng Vọng gets built by every Claude session that works in this repo, so treat each session as a chance to move the
build forward, not only to answer:
- **Where the build is:** the newest work is on branch `full-game` (built on `m3-night1` and `factory-prototype`; not
  merged into `main` yet). Its `docs/PROGRESS.md` is the real state: M0–M6 done, M7/M8 partly. Read it there
  (`git fetch` then `git show origin/full-game:docs/PROGRESS.md`) before planning work, and base build work on that branch.
- **What's open** (in that file's "Next" and the unchecked milestones): first, run the tests on Catlyn's 2026-11-02
  changes (Im lặng takes players one by one, Bin's new Tape 2, `test.py --art`; nobody has run them yet); then the
  art pass with Creator Store models (export it with `tools/art/`, test with `--art`), music for the finale and
  sounds for Tí's clay whistle and Khoa's drum. Catlyn reviewed every DRAFT text on 2026-11-02; what's left for her in
  `docs/DECISIONS.md` needs Studio or a file from her (Tape 2 and finale staging once seen, the sounds once heard,
  the map image). The Quiet Man / Silence is left out until after the first playtest.
- **When a request is done and the session has room left,** offer the next open task that fits, in one line. When the
  human has asked for build work, take the next task without waiting to be asked again.
- **On GitHub (the bot):** end each answer with one next build step small enough for a single run, and say
  "reply `@claude go` to do it". Work that needs Studio (art, playtests, `tools/factory/test.py`) is for a local session.
- **In a local session with Studio:** that's where the art pass, the playtests and the tests happen; prefer those tasks there.
- Stay inside the weekly budget (see `docs/ASK_CLAUDE.md`): if the bot has posted a budget heads-up this week, keep to small steps.
