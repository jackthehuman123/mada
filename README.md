# Làng Vọng

A co-op story-horror game for Roblox, built on the Vietnamese *ma da* folklore and ghost month (*Rằm tháng bảy*). Four ghost-hunting friends walk into an abandoned lake village where the lanterns light themselves, lose their cameraman to the water, and have to work out who the girl in the lake is, and who is still waiting for her.

This repo holds the design and the prototype code. It's set up so a coding agent (Claude Code) can build the prototype in Roblox Studio by following the files.

## Repo map

| Path | What it is |
| --- | --- |
| `docs/GAME.md` | Game rules and facts for agents. |
| `CLAUDE.md` | Claude Code entry point (router). |
| `docs/ASK_CLAUDE.md` | Asking Claude on GitHub: write `@claude` in an issue or pull request (setup + how to). |
| `.claude/agents/` | Specialist subagents: world-builder, qa-tester, story-keeper, voice-over, sound-designer. |
| `docs/PROTOTYPE_BRIEF.md` | The build spec: scope, rules, numbers, map, milestones, defaults. |
| `docs/design/` | Catlyn's design docs: story, gameplay, characters, threats, timeline, release plan. |
| `docs/MCP_SETUP.md` | Setting up Rojo and the Roblox Studio MCP server; free assets and 3D models. |
| `docs/ASSETS.md` | Asset rules, Creator Store search list, asset log. |
| `docs/PROGRESS.md` | Milestone checklist and session log (the agent keeps it updated). |
| `docs/DECISIONS.md` | Choices the agent made and drafts waiting for review. |
| `src/` | Luau code, synced into Studio by Rojo. |
| `src/server/World/` | The graybox village as code (`Build.luau`): the server builds it when the place has no world yet; the tests always use it. |
| `tools/worldgen/` | Scripts the agent runs in Studio to build the world. `00_graybox.luau` bakes the graybox from `Build.luau` into the open place. |
| `tools/factory/`, `tests/` | The factory test runner and the acceptance tests: `python tools/factory/test.py` (see `docs/FACTORY.md`). |
| `audio/` | Generated voice-over, music and SFX files waiting to be uploaded to Roblox. |

## Getting started (builder)

**Fastest:** clone `mada`, open Claude Code in the folder and type **`/setup`**. It checks the tools, switches to the newest build, checks the game runs, and offers the next task.

1. Follow **`docs/SETUP.md`** once (Windows or macOS): install Git, Claude Code and Rokit; SSH key; clone `mada`; `rokit install`; `rojo plugin install`; open the shared place; enable Studio's MCP server and Quick-connect Claude Code.
2. Each session:
   - Open the place in Roblox Studio.
   - `rojo serve` in this folder, then **Plugins → Rojo → Connect** in Studio.
   - Open Claude Code in this folder and say:
     > Read CLAUDE.md and follow it. Begin the next milestone in docs/PROGRESS.md.
3. When the agent finishes a step, `python tools/factory/test.py` must say PASS; then push the commits and **save/publish the place** (world-builder's work lives there).

## Working together

- **Catlyn** owns the story and design (`docs/design/`). Edit those files and push; the agent re-reads them each session.
- Review anything marked `DRAFT` (in `docs/DECISIONS.md` and `src/shared/Content/`) — that's text the agent wrote from the story.
- **Code** is shared through git. **The world** has two layers: the graybox layout in `src/server/World/Build.luau` (git; the server builds it only when the place has no world yet, and the tests always use it) and everything world-builder adds in the shared place (save/publish it). Only one person runs `rojo serve` into a shared place at a time.
