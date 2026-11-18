---
description: Set this computer up to build Làng Vọng, get onto the newest build, check that it runs, then pick up the next build task. Run it once on a new computer, and again whenever something stops working.
---

# /setup: get this computer ready to build Làng Vọng

You are setting up the human's computer so the two of you can keep building the game. Do the steps in order. Keep the
human informed in one short line per step (what you checked, what you did). Stop and ask whenever a step needs them
(installing software, a Studio setting, a restart). Never print or ask them to paste tokens, keys or passwords.

## 1. Tools

Check each, and report the versions in one line:
- `git --version`
- `rokit --version` (the Roblox toolchain manager)
- `python --version` or `python3 --version` (3.10 or newer; needed by the test runner)
- `claude --version`
- Roblox Studio installed and signed in once. Windows: a `RobloxStudioBeta.exe` under `%LOCALAPPDATA%\Roblox\Versions\`.
  macOS: `/Applications/RobloxStudio.app`.

If something is missing, show the exact install lines from `docs/SETUP.md` §1 for their system (Windows or macOS) and
wait for them to install it. Don't install software yourself without their yes.

## 2. The newest build

The game is built on branches, newest last: `factory-prototype` → `m3-night1` → `full-game`. `main` may not have it yet.
1. `git status`: if there are uncommitted changes, stop and ask what to do with them (commit, stash, or leave).
2. `git fetch origin`
3. Work out where the newest build is: if `git merge-base --is-ancestor origin/full-game origin/main` succeeds, `main`
   already has it: use `main`. Otherwise use `full-game` (`git switch full-game`, which tracks `origin/full-game`).
4. `git pull` on that branch. Tell the human which branch you're on and why.

## 3. Roblox toolchain

1. `rokit install` (answer yes to trusting `rojo-rbx/rojo` and `lune-org/lune`). Check `rojo --version` matches `rokit.toml`.
2. `rojo plugin install`. If it fails, follow `docs/SETUP.md` §3 (open Studio once, or install `Rojo.rbxm` by hand).

## 4. Studio ↔ Claude

Check with `claude mcp list` whether a Roblox Studio server (often `Roblox_Studio`) is listed and connected.
If not, walk the human through `docs/SETUP.md` §5: in Studio, Assistant → … → Manage MCP Servers → turn on
**Enable Studio as MCP server** → under Quick connect turn on **Claude Code** → restart Studio. If it still isn't
listed, give them the one `claude mcp add` line from §5 for their system. Adding an MCP server needs a Claude Code
restart: tell them to restart and type `/setup` again, then stop.

## 5. Does it run?

- **Windows:** run `python tools/factory/test.py 01` (it builds the game from git, opens its own Studio window for a
  minute or two, plays it, checks it boots, and closes the window). It must say PASS. Then offer the full run:
  `python tools/factory/test.py` (all 9 test files, about 10 minutes).
- **macOS:** the test runner is Windows-only for now. Instead run `rojo build default.project.json -o build/langvong.rbxl`,
  tell them to open `build/langvong.rbxl` in Studio and press Play, and ask what they see. Porting the runner to macOS
  is a good first build task if they're on a Mac.

If something fails, read the report (`tools/factory/reports/<newest>/report.md`) and fix what's ours, or explain what
the human needs to do.

## 6. Ready: pick up the build

1. Read `docs/ISSUES.md` on this branch (the open issues and what each needs) and `docs/PROGRESS.md` for context.
2. Tell the human in a few lines: which branch, that it runs, what's done, what's open.
3. Offer the next open task that fits this session (the first open issue in `docs/ISSUES.md` whose *Needs* fits),
   and the items under *Waiting on Catlyn*. If they say go, start it, following
   `CLAUDE.md` and `docs/GAME.md`.

Optional, only if they ask: `@claude` on GitHub (`docs/ASK_CLAUDE.md`) needs the repo owner to install the Claude
GitHub app and add their own token as a repo secret.
