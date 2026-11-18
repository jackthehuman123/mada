# Làng Vọng — Claude Code router

Playable prototype of a 1–4 player co-op story-horror Roblox game (Vietnamese *ma da* folklore). Luau, Rojo 7.7+, Lune tests.
Game rules, story limits and tone: `docs/GAME.md`. Where the build stands: `docs/STATE.md`. Open work: `docs/ISSUES.md`.

## Repo map
- `src/server/` → `ServerScriptService.Server`: `Services/` (one module per system), `SceneLoader`, `Scenes/<name>/{layout,mood}.luau`, `World/Build.luau` (graybox)
- `src/client/` → `Controllers/` (UI, camcorder, sound); `src/shared/` → `ReplicatedStorage.Shared`: `Config`, `Tags`, `Remotes`, `Content/` (all player text), `Scene/` (validators)
- `assets/prefabs/*.rbxm` — built pieces (made rarely); `tools/` — `check.sh`, `extract-prefabs.luau`, `factory/test.py`, `worldgen/`
- `tests/` — Lune specs (`*.spec.luau`) and Studio factory tests (`NN_*.luau`); `docs/specs/` — one spec per feature
- `docs/MODULES.md` is the code index; `docs/CONVENTIONS.md` the code rules; `docs/REVIEW_CHECKLIST.md` the reviewer's list

## Workflow
spec (`docs/specs/`) → build → `tools/check.sh` → reviewer only if risky → Catlyn playtests in Studio → write her words in the spec's Feedback log → update `docs/STATE.md`.
Risky = remotes, DataStore, anything trusting the client, or a diff over ~150 lines.

## Model routing
explorer = haiku; builder, world-builder, studio-tester = sonnet; reviewer = opus.

## Rules
- Read `docs/MODULES.md` before searching code.
- Never search the notes vault (`~/Documents/vaults/roblox-brain`); anything needed is excerpted in `docs/GAME.md` or a spec.
- Never read whole Studio trees through MCP; query specific paths or tags.
- Scenes change through `layout.luau` / `mood.luau`, never by hand-placing parts. Code goes through file edits in `src/`, never MCP `multi_edit` on Rojo-managed scripts.
- Run `tools/check.sh` before saying done; it prints `OK` or at most 30 `file:line: message` lines.
- Before changing anything that has a spec, read every "Decided" line in its Feedback log; never revert one without asking.
- Player-facing text lives in `src/shared/Content/`; numbers in `src/shared/Config.luau`; world objects are found by tag (`src/shared/Tags.luau`).
- Don't invent story. Facts come from `docs/design/story.md`; new wording is marked `-- DRAFT: needs Catlyn review` and logged in `docs/DECISIONS.md`.
- Never read `Packages/**`, `*.rbxl`, `*.rbxlx`, `*.rbxm`, `sourcemap.json`, `work/**`.
- Run shell commands one at a time; never chain with `&&` or `;`.
- One Studio user at a time (one place, one playtest). Stop and ask for: publishing, roblox.com settings, Robux, uploads, her account, or any change to the story or an ending.
- End of a task: update `docs/STATE.md` and `docs/ISSUES.md`, log choices in `docs/DECISIONS.md`, commit, remind Catlyn to save the place in Studio. Don't push unless asked.
