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
