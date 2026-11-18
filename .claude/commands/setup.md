---
description: Set this computer up to build Làng Vọng, get onto the newest build, check that it runs, then pick up the next build task. Run it once on a new computer, and again whenever something stops working.
---

# /setup: get this computer ready to build Làng Vọng

Do the steps in order. Tell the human one short line per step (what you checked, what you did). Stop and ask whenever
a step needs them (installing software, a Studio setting, a restart). Never print or ask them to paste tokens, keys or
passwords. Run shell commands one at a time.

## 1. Tools
Check each and report the versions in one line: `git --version`, `rokit --version`, `jq --version`, `claude --version`,
and Roblox Studio installed and signed in once (macOS: `/Applications/RobloxStudio.app`; Windows: `RobloxStudioBeta.exe`
under `%LOCALAPPDATA%\Roblox\Versions\`). `tools/check.sh` and the post-edit hook are bash scripts (Windows: Git Bash).
If something is missing, show the install lines from `docs/SETUP.md` §1 for their system (jq: macOS 15+ ships it,
otherwise `brew install jq`; Windows `winget install jqlang.jq`) and wait. Don't install software without their yes.

## 2. The newest build
1. `git status`: if there are uncommitted changes, stop and ask what to do with them (commit, stash, or leave).
2. `git fetch origin`, then stay on the current branch and `git pull`. If they're on `main` or unsure, use `main`.
   Tell them which branch you're on.

## 3. Roblox toolchain
1. `rokit install` (answer yes to trusting the tools in `rokit.toml`). Check `rojo --version` matches `rokit.toml`.
2. `rojo plugin install`. If it fails, follow `docs/SETUP.md` §3.
3. `tools/check.sh` must print `OK`. The first run downloads Roblox type definitions into `tools/types/` (needs
   internet). A `missing tools` line means step 1 didn't finish.

## 4. Studio ↔ Claude
Check with `claude mcp list` that a Roblox Studio server (often `Roblox_Studio`) is listed and connected. If not, walk
them through `docs/SETUP.md` §5 (Studio: Assistant → … → Manage MCP Servers → **Enable Studio as MCP server** → Quick
connect **Claude Code** → restart Studio). Adding an MCP server needs a Claude Code restart: tell them to restart and
type `/setup` again, then stop.

## 5. Does it run?
Tell them to run `rojo serve`, connect the Rojo plugin in Studio and press Play. The Output should show
`[LangVong] scene village: … prefabs placed` and `[LangVong] server started`, with no red errors from our scripts.
On Windows, `python tools/factory/test.py 01` also runs the boot test on its own (`docs/FACTORY.md`).

## 6. Ready: pick up the build
1. Read `docs/STATE.md` and the *Open* list in `docs/ISSUES.md`.
2. Tell them in a few lines: which branch, that it runs, what's done, what's open.
3. Offer the first open issue whose *Needs* fits this computer, and the items under *Waiting on Catlyn*. If they say
   go, start it following `CLAUDE.md`.
