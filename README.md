# Làng Vọng

A co-op story-horror game for Roblox, built on the Vietnamese *ma da* folklore and ghost month (*Rằm tháng bảy*). Four ghost-hunting friends walk into an abandoned lake village where the lanterns light themselves, lose their cameraman to the water, and have to work out who the girl in the lake is, and who is still waiting for her.

This repo holds the design and the prototype code. It's set up so a coding agent (Claude Code or any agent that reads `AGENTS.md`) can build the prototype in Roblox Studio by following the files.

## Repo map

| Path | What it is |
| --- | --- |
| `AGENTS.md` | Instructions for any coding agent. Start here. |
| `CLAUDE.md` | Claude Code entry point (imports `AGENTS.md`). |
| `docs/ASK_CLAUDE.md` | Asking Claude on GitHub: write `@claude` in an issue or pull request (setup + how to). |
| `.claude/agents/` | Specialist subagents: world-builder, qa-tester, story-keeper, voice-over, sound-designer. |
| `docs/PROTOTYPE_BRIEF.md` | The build spec: scope, rules, numbers, map, milestones, defaults. |
| `docs/design/` | Catlyn's design docs: story, gameplay, characters, threats, timeline, release plan. |
| `docs/MCP_SETUP.md` | Setting up Rojo and the Roblox Studio MCP server; free assets and 3D models. |
| `docs/ASSETS.md` | Asset rules, Creator Store search list, asset log. |
| `docs/PROGRESS.md` | Milestone checklist and session log (the agent keeps it updated). |
| `docs/DECISIONS.md` | Choices the agent made and drafts waiting for review. |
| `src/` | Luau code, synced into Studio by Rojo. |
| `tools/worldgen/` | Scripts the agent runs in Studio to build the world. |
| `audio/` | Generated voice-over, music and SFX files waiting to be uploaded to Roblox. |

## Getting started (builder)

**Fastest:** clone `mada`, open Claude Code in the folder and type **`/setup`**. It checks the tools, switches to the newest build, checks the game runs, and offers the next task.

1. Follow **`docs/SETUP.md`** once (Windows or macOS): install Git, Claude Code and Rokit; SSH key; clone `mada`; `rokit install`; `rojo plugin install`; open the shared place; enable Studio's MCP server and Quick-connect Claude Code.
2. Each session:
   - Open the place in Roblox Studio.
   - `rojo serve` in this folder, then **Plugins → Rojo → Connect** in Studio.
   - Open Claude Code in this folder and say:
     > Read CLAUDE.md and follow it. Begin the next milestone in docs/PROGRESS.md.
3. When the agent finishes a step, **save/publish the place in Studio** and push the commits.

## Working together

- **Catlyn** owns the story and design (`docs/design/`). Edit those files and push; the agent re-reads them each session.
- Review anything marked `DRAFT` (in `docs/DECISIONS.md` and `src/shared/Content/`) — that's text the agent wrote from the story.
- **Code** is shared through git. **The world** (terrain, buildings, models) lives in the published Roblox place; add each other as collaborators in Game Settings → Permissions and use Team Create to work in the same place. Only one person runs `rojo serve` into it at a time.
