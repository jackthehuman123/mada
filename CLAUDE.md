@AGENTS.md

# Claude Code notes

- `AGENTS.md` (imported above) is the full instruction set and applies to you. Everything below is Claude-specific.
- The Roblox Studio MCP server is usually registered as `Roblox_Studio`, so its tools appear as `mcp__Roblox_Studio__<tool>` (for example `mcp__Roblox_Studio__execute_luau`). If none appear, run `/mcp` to check status, then follow `docs/MCP_SETUP.md`.
- When the human says "continue" or "begin", start with the start-of-session routine in `AGENTS.md`, then work on the next unchecked task in `docs/PROGRESS.md`.
- Use the task list for the milestone's tasks so the human can see progress.
- For a whole milestone, plan first (list files to create, tags, remotes, test steps), then build. Keep each commit to one coherent step.
- Code goes through normal file edits in `src/`. Use MCP for the world, assets, playtests, console and screenshots, not for editing Rojo-managed scripts.
- Read big design docs with targeted reads when you only need one section; `story.md` is long.
