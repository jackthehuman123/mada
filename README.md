# Làng Vọng

A co-op story-horror game for Roblox, built on the Vietnamese *ma da* folklore and ghost month (*Rằm tháng bảy*). Four ghost-hunting friends walk into an abandoned lake village where the lanterns light themselves, lose their cameraman to the water, and have to work out who the girl in the lake is, and who is still waiting for her.

This repo holds the design and the prototype code. It's set up so a coding agent (Claude Code or any agent that reads `AGENTS.md`) can build the prototype in Roblox Studio by following the files.

## Repo map

| Path | What it is |
| --- | --- |
| `AGENTS.md` | Instructions for any coding agent. Start here. |
| `CLAUDE.md` | Claude Code entry point (imports `AGENTS.md`). |
| `docs/PROTOTYPE_BRIEF.md` | The build spec: scope, rules, numbers, map, milestones, defaults. |
| `docs/design/` | Catlyn's design docs: story, gameplay, characters, threats, timeline, release plan. |
| `docs/MCP_SETUP.md` | Setting up Rojo and the Roblox Studio MCP server; free assets and 3D models. |
| `docs/ASSETS.md` | Asset rules, Creator Store search list, asset log. |
| `docs/PROGRESS.md` | Milestone checklist and session log (the agent keeps it updated). |
| `docs/DECISIONS.md` | Choices the agent made and drafts waiting for review. |
| `src/` | Luau code, synced into Studio by Rojo. |
| `src/server/World/` | The village, built by the server from code at startup (graybox, tagged). |
| `tools/factory/`, `tests/` | The factory test runner and the acceptance tests: `python tools/factory/test.py` (see `docs/FACTORY.md`). |

## Getting started (builder)

1. Follow `docs/MCP_SETUP.md` §1–4 once: install Studio, Git, Claude Code and Rokit; `rokit install`; `rojo plugin install`; create and publish the place; enable Studio's MCP server and Quick-connect Claude Code.
2. Each session:
   - Open the place in Roblox Studio.
   - `rojo serve` in this folder, then **Plugins → Rojo → Connect** in Studio.
   - Open Claude Code in this folder and say:
     > Read CLAUDE.md and follow it. Begin the next milestone in docs/PROGRESS.md.
3. When the agent finishes a step, `python tools/factory/test.py` must say PASS; then push the commits. (The world is built from code, so there's no place file to save for it.)

## Working together

- **Catlyn** owns the story and design (`docs/design/`). Edit those files and push; the agent re-reads them each session.
- Review anything marked `DRAFT` (in `docs/DECISIONS.md` and `src/shared/Content/`) — that's text the agent wrote from the story.
- **Code and the world** are shared through git: the village is built from `src/server/World/Build.luau` when the server starts, so nobody's unsaved place can lose it. Only one person runs `rojo serve` into a shared place at a time.
