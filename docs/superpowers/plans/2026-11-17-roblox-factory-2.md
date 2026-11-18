# roblox-factory 2.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (Catlyn chose native execution) to implement this plan task-by-task, one task per session with `/clear` between tasks. After Task 8, dispatch one fresh reviewer on the most capable model over the whole branch. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the `mada` repo into a token-efficient agent factory: quiet automatic checks, a lean router-style brain, agents with fixed models, and a modular build pipeline (prefabs + layout data + mood data) with git rollback.

**Architecture:** Code and builds both follow one rule: *make pieces once, iterate on how they're combined.* Built pieces are `.rbxm` prefabs synced by Rojo; scenes are small pure-data Luau files (layout + mood) that a thin `SceneLoader` turns into instances. All pure logic is Lune-tested; engine glue is kept thin and checked by playtest. Catlyn's feedback is written into each spec's feedback log so it survives `/clear`.

**Tech Stack:** Rokit, Rojo, Wally, StyLua, selene, luau-lsp, Lune, Claude Code (subagents, skills, hooks), Roblox Studio MCP.

**Spec:** No separate design doc — the decisions below came from the brainstorming conversation and are the spec.

## Design decisions (the spec)

1. **Build inside `mada`, not a blank template.** Extract a reusable `roblox-factory` template only when a second game starts. *(Claude's call — flip by running Tasks 1–8 in an empty repo instead.)*
2. **Built things = option C:** prefabs (`assets/prefabs/*.rbxm`, made rarely) + per-scene `layout.luau` and `mood.luau` (pure data, edited often). Rollback is `git`. Agents never read `.rbxm`/`.rbxl` files.
3. **Measure before optimizing.** Task 0 records a baseline on the current setup; Task 9 compares.
4. **Feedback survives `/clear`.** Every spec has a `## Feedback log`; builders read all "Decided" lines before any change and never revert one without asking.
5. **Review chain scales with risk.** Builder + `check.sh` by default; the Opus reviewer runs only for remotes, DataStore, anything trusting the client, or diffs over ~150 lines.
6. **Catlyn reviews by playing in Studio herself.** `studio-tester` uses console output only; screenshots only when she asks. *(Claude's call — she didn't answer this; change Task 7 if she wants agents to bring visuals.)*
7. **No hand-rolled infrastructure.** Shared libraries (Signal, Janitor, data persistence) come from Wally, added only when a feature needs them.
8. **The vault stays out.** `~/Documents/vaults/roblox-brain` is never searched by agents; relevant excerpts get pasted into `docs/GAME.md` or a spec. `docs/GAME.md` is the source of truth for anything agents depend on.

## Global Constraints

- Luau `--!strict` in every `.luau` file under `src/` and `tools/`.
- `tools/check.sh` prints exactly `OK` on success; on failure only `file:line: message` lines, at most 30, exit 1.
- `CLAUDE.md` ≤ 60 lines. `docs/STATE.md` ≤ 40 lines. Each `SKILL.md` ≤ 50 lines of steps. Each agent file ≤ 40 lines.
- Agents may not Read/Grep/Glob: `Packages/**`, `**/*.rbxl`, `**/*.rbxlx`, `**/*.rbxm`, `sourcemap.json`, `work/**`.
- Prefab names match `^[A-Za-z][A-Za-z0-9_]*$` and are unique.
- Layout/mood files contain only numbers, strings, booleans and tables — no Roblox datatypes — so Lune can load them.
- Work on the Mac mini (it runs Studio). One task per Claude Code session; `/clear` between tasks.
- Rojo is pinned at **7.7.0 or newer**: 7.6.1 can't read models saved by current Studio (rojo-rbx/rojo#1284). The Studio plugin must match (`rojo plugin install`).
- Rojo mounts `src/server` as `ServerScriptService.Server`; use paths like `ServerScriptService.Server.SceneLoader`.
- Agents run shell commands one at a time; no chaining with `&&` or `;` (chains get blocked by permission rules and cost retries).

## Review Focus

1. **A layout names a prefab that doesn't exist** (typo, deleted prefab): the Lune test fails naming the scene, entry index and name; at runtime the loader skips that entry with a warning instead of erroring.
2. **A scene is loaded twice** (edit-mode preview, then playtest): no duplicates — the loader clears its own scene folder first.
3. **Bad numbers in layout/mood** (`at` with 2 values, `fogEnd < fogStart`, colour 300): validation reports each problem; nothing is applied half-way.
4. **Workshop has duplicate or invalid prefab names, or a non-Model child:** extraction refuses duplicates/invalid names with a message and skips non-Models; it never writes a bad file.
5. **Hook fires on a non-Luau file or a deleted file:** exits 0 silently; never blocks an edit.

Each line has a test in the owning task (Tasks 2, 3, 4, 5).

---

### Task 0: Baseline measurement (Catlyn does this by hand — not an agent task)

- [ ] **Step 1:** On the current mada setup, run two real tasks: one small Luau feature and one "change this part of the world" request.
- [ ] **Step 2:** In each session, run `/context` halfway and `/cost` at the end. Write both numbers plus one line on what went wrong (rework, forgotten feedback, broken thing) into `docs/BASELINE.md`.
- [ ] **Step 3:** Commit: `git add docs/BASELINE.md && git commit -m "docs: token baseline before factory 2.0"`

---

### Task 1: Toolchain, quiet check, test runner

**Files:**
- Create/modify: `rokit.toml`, `selene.toml`, `stylua.toml`, `.luaurc`, `.gitignore`
- Create: `tools/check.sh`, `tests/run.luau`, `tests/smoke.spec.luau`

**Interfaces:**
- Produces: `tools/check.sh` (contract in Global Constraints). Spec files are `tests/**/*.spec.luau`, each returning `function(test: (name: string, fn: () -> ()) -> ())`.

- [ ] **Step 1:** Read the existing `default.project.json`, `rokit.toml`/`aftman.toml` and `src/` layout. Keep whatever mada already has; only add what's missing.
- [ ] **Step 2:** Pin via `rokit add`: `rojo-rbx/rojo`, `UpliftGames/wally`, `JohnnyMorganz/StyLua`, `Kampfkarren/selene`, `JohnnyMorganz/luau-lsp`, `lune-org/lune`. Run `rokit install`. Expected: all six print a version with `--version`.
- [ ] **Step 3:** Configs: `selene.toml` `std = "roblox"`; `.luaurc` `{"languageMode": "strict"}`; `.gitignore` adds `Packages/`, `*.rbxl`, `*.rbxlx`, `sourcemap.json`, `work/`, `tools/types/`. Do **not** ignore `*.rbxm` (prefabs are versioned).
- [ ] **Step 4: Write the smoke spec**

```lua
-- tests/smoke.spec.luau
return function(test)
	test("arithmetic works", function()
		assert(1 + 1 == 2, "expected 2")
	end)
end
```

- [ ] **Step 5:** Implement `tests/run.luau`: discover `tests/**/*.spec.luau` with `@lune/fs`, run each test in `pcall`, print nothing for passes, print `<file>: <test name>: <error>` per failure, `process.exit(1)` if any failed. If Lune rejects a computed `require` path, fall back to an explicit list in `tests/specs.luau`.
- [ ] **Step 6:** Implement `tools/check.sh`: `stylua --check src tools tests`, `selene src tools tests`, `rojo sourcemap -o sourcemap.json` then `luau-lsp analyze` with Roblox definitions cached in `tools/types/` (check `luau-lsp analyze --help` for the flag name), then `lune run tests/run`. Collect output, normalize to `file:line: message`, `head -30`, print `OK` only if all passed.
- [ ] **Step 7: Verify both paths.** Run `tools/check.sh` → expected exactly `OK`. Temporarily change the smoke assertion to `1 + 1 == 3`, run → expected one line containing `smoke.spec.luau` and exit 1. Revert.
- [ ] **Step 8:** Commit: `git commit -am "build: pinned toolchain and quiet check.sh"` (add new files first).

---

### Task 2: Guardrails — permissions and format-on-edit hook

**Files:**
- Create/modify: `.claude/settings.json`
- Create: `tools/hooks/post-edit.sh`, `tests/hook.test.sh`

**Interfaces:**
- Consumes: StyLua from Task 1.
- Produces: hook reads the Claude Code hook JSON on stdin, uses `.tool_input.file_path`.

- [ ] **Step 1: Write the hook test** `tests/hook.test.sh` with three cases, each asserting exit code 0 and empty stdout+stderr:
  1. a badly formatted `.luau` temp file → after the hook, `stylua --check` on it passes;
  2. a `.md` file path → untouched;
  3. a path that doesn't exist → no error.
- [ ] **Step 2:** Run `bash tests/hook.test.sh` → expected FAIL (script missing).
- [ ] **Step 3:** Implement `tools/hooks/post-edit.sh`: parse `file_path` with `jq`; if it ends in `.luau` and exists, run `stylua "$file"` quietly; always exit 0. **No linting here** — lint runs in `check.sh`, so half-finished multi-file edits don't trigger retries.
- [ ] **Step 4:** Run `bash tests/hook.test.sh` → expected PASS.
- [ ] **Step 5:** `.claude/settings.json`: `permissions.deny` = Read/Grep/Glob on every path in Global Constraints' deny list; `permissions.allow` = `Bash(tools/check.sh)`, `Bash(rojo *)`, `Bash(lune *)`, `Bash(git status)`, `Bash(git diff*)`, `Bash(git log*)`; `hooks.PostToolUse` matcher `Edit|Write` → `tools/hooks/post-edit.sh`.
- [ ] **Step 6:** Ask Claude Code to read `Packages/` (or any `.rbxl`) → expected: denied.
- [ ] **Step 7:** Commit: `git commit -m "chore: agent permissions and format-on-edit hook"`.

---

### Task 3: Scene data and validation (pure, Lune-tested)

**Files:**
- Create: `src/shared/Scene/Layout.luau`, `src/shared/Scene/Mood.luau`
- Create: `src/server/Scenes/village/layout.luau`, `src/server/Scenes/village/mood.luau`
- Test: `tests/scene.spec.luau`, `tests/scenes_reference_prefabs.spec.luau`

**Interfaces:**
- Produces:
```lua
-- Layout.luau
export type Entry = { prefab: string, at: {number}, rot: number?, tags: {string}? }
function Layout.validate(entries: {Entry}, prefabNames: {[string]: boolean}): {string}
-- Mood.luau
export type Mood = {
	clockTime: number, brightness: number,
	fogStart: number, fogEnd: number,
	fogColor: {number}, ambient: {number},
	atmosphereDensity: number?,
}
function Mood.validate(mood: Mood): {string}
```
Both return a list of error strings; empty list = valid. Messages start with `entry <i>:` (layout) or the field name (mood).

- [ ] **Step 1: Write failing tests** in `tests/scene.spec.luau`:

```lua
local Layout = require("../src/shared/Scene/Layout")
local Mood = require("../src/shared/Scene/Mood")
local names = { StiltHouse_A = true, Shrine = true }

return function(test)
	test("valid layout has no errors", function()
		local errs = Layout.validate({ { prefab = "Shrine", at = { 0, 4, 30 } } }, names)
		assert(#errs == 0, table.concat(errs, "; "))
	end)
	test("unknown prefab is reported with index and name", function()
		local errs = Layout.validate({ { prefab = "Shrine", at = { 0, 0, 0 } }, { prefab = "Shrin", at = { 0, 0, 0 } } }, names)
		assert(#errs == 1 and errs[1]:find("entry 2") and errs[1]:find("Shrin"), errs[1])
	end)
	test("'at' must be exactly 3 numbers", function()
		local errs = Layout.validate({ { prefab = "Shrine", at = { 1, 2 } } }, names)
		assert(#errs == 1 and errs[1]:find("entry 1"), "expected at error")
	end)
	test("mood rejects fogEnd below fogStart and colour over 255", function()
		local errs = Mood.validate({ clockTime = 2, brightness = 1, fogStart = 100, fogEnd = 50, fogColor = { 300, 0, 0 }, ambient = { 0, 0, 0 } })
		assert(#errs == 2, `expected 2 errors, got {#errs}`)
	end)
	test("mood rejects clockTime outside [0, 24)", function()
		local errs = Mood.validate({ clockTime = 24, brightness = 1, fogStart = 0, fogEnd = 100, fogColor = { 0, 0, 0 }, ambient = { 0, 0, 0 } })
		assert(#errs == 1 and errs[1]:find("clockTime"), "expected clockTime error")
	end)
end
```

- [ ] **Step 2:** `tools/check.sh` → expected FAIL (modules missing).
- [ ] **Step 3:** Implement `Layout.validate` and `Mood.validate` with the signatures above. Rules: `at` = 3 numbers; `rot` optional number (degrees, yaw); `tags` optional list of strings; colours = 3 numbers in 0–255; `fogEnd > fogStart`; `clockTime` in [0, 24); `atmosphereDensity` optional in [0, 1].
- [ ] **Step 4:** Create `village/layout.luau` returning `{}` for now and `village/mood.luau` with a night horror baseline (`clockTime = 0`, low brightness, short grey-green fog). Values are the builder's taste call; Catlyn adjusts.
- [ ] **Step 5: Write the cross-check test** `tests/scenes_reference_prefabs.spec.luau`: build the name set from file stems in `assets/prefabs/`, then for every directory in `src/server/Scenes/` require its `layout` and `mood` and assert both `validate` calls return no errors; failure message includes the scene name.
- [ ] **Step 6:** `tools/check.sh` → expected `OK`.
- [ ] **Step 7:** Commit: `git commit -m "feat: scene layout and mood data with validation"`.

---

### Task 4: SceneLoader (thin engine glue) and Rojo mapping

**Files:**
- Modify: `default.project.json`
- Create: `assets/prefabs/.gitkeep`, `src/server/SceneLoader.luau`, `src/server/Scenes/active.luau`
- Modify: the server bootstrap script (find it via `docs/MODULES.md` or the explorer agent)

**Interfaces:**
- Consumes: `Layout.validate`, `Mood.validate` (Task 3).
- Produces:
```lua
function SceneLoader.load(sceneName: string): (number, {string}) -- placed count, warnings
```
Prefabs live at `ServerStorage.Prefabs`; scenes are placed under `workspace.Scenes.<sceneName>`. `Scenes/active.luau` returns `{string}`, the scene names to load at server start.

- [ ] **Step 1:** In `default.project.json` map `ServerStorage.Prefabs` → `assets/prefabs` and keep `src/server/Scenes` under the server tree.
- [ ] **Step 2:** Implement `SceneLoader.load`: destroy and recreate `workspace.Scenes[sceneName]` (so loading twice never duplicates); run both validators, and if mood is invalid, return its errors without touching `Lighting`; for each entry, skip unknown prefabs with a warning, else `Clone()`, `PivotTo(CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(rot or 0), 0))`, add `tags` via CollectionService, parent to the scene folder; apply mood to `Lighting` (+ an `Atmosphere` child when `atmosphereDensity` is set). Under ~120 lines; no other logic belongs here.
- [ ] **Step 3:** Bootstrap calls `SceneLoader.load` for each name in `active.luau` (start with `{"village"}`) and `warn`s each warning.
- [ ] **Step 4:** `tools/check.sh` → expected `OK`.
- [ ] **Step 5: Studio check (one MCP call, or Catlyn by hand).** With `rojo serve` running, put one throwaway Model named `Probe` in `assets/prefabs` (via Task 5 or Studio's Save to File), set village layout to two entries (`Probe`, `Missing`), then in edit mode run `require(game.ServerScriptService.SceneLoader).load("village")` **twice**. Expected: returns `1` and one warning mentioning `Missing`; `workspace.Scenes.village` contains exactly one `Probe`. Remove the probe entries afterwards.
- [ ] **Step 6:** Commit: `git commit -m "feat: SceneLoader places prefabs from layout data"`.

---

### Task 5: Prefab extraction tool (Lune, zero model tokens)

**Files:**
- Create: `tools/lib/prefabNames.luau`, `tools/extract-prefabs.luau`
- Test: `tests/prefab_names.spec.luau`, `tests/extract.spec.luau`

**Interfaces:**
- Produces:
```lua
function prefabNames.check(names: {string}): {string} -- errors: invalid names, duplicates
```
CLI: `lune run tools/extract-prefabs <place.rbxl> [folderName]` (default folder `PrefabWorkshop` in Workspace). Writes `assets/prefabs/<Name>.rbxm` per Model child, overwriting (git is the rollback); prints `wrote N prefabs` plus one line per skipped child.

- [ ] **Step 1: Write failing tests** — `prefab_names.spec.luau`:
  - `check({"StiltHouse_A", "Shrine"})` → `{}`
  - `check({"Shrine", "Shrine"})` → 1 error containing `duplicate` and `Shrine`
  - `check({"2Lantern", "Old House"})` → 2 errors, each containing the bad name

  `extract.spec.luau`: build a DataModel in Lune with `Workspace.PrefabWorkshop` holding Models `A`, `B` and a `Part` named `Loose`; serialize to a temp `.rbxl`; run extraction into a temp output dir; assert exactly `A.rbxm` and `B.rbxm` exist and stdout mentions `Loose` as skipped. With two Models both named `A`, assert no files are written and exit code is non-zero.
- [ ] **Step 2:** `tools/check.sh` → expected FAIL.
- [ ] **Step 3:** Implement `prefabNames.check` (pattern from Global Constraints) and `extract-prefabs.luau` using `@lune/roblox` `deserializePlace` / `serializeModel`; run `check` on all Model names **before** writing anything; accept an optional output dir argument for tests.
- [ ] **Step 4:** Add `rojo build -o /tmp/check.rbxl` to `tools/check.sh` (output normalized like the rest), so a prefab Rojo can't read fails the check instead of crashing `rojo serve`. Verify: put a zero-byte `assets/prefabs/Bad.rbxm` in place → check.sh prints one line naming `Bad.rbxm`; delete it.
- [ ] **Step 5:** `tools/check.sh` → expected `OK`.
- [ ] **Step 6:** Commit: `git commit -m "feat: extract Studio prefabs to versioned rbxm files"`.

**Workflow this enables:** build or tweak prefabs in Studio inside `Workspace.PrefabWorkshop` → File › Save to File as `work/workshop.rbxl` → `lune run tools/extract-prefabs work/workshop.rbxl` → `git diff --stat` shows which prefabs changed → commit.

---

### Task 6: The lean brain (docs)

**Files:**
- Create/replace: `CLAUDE.md`, `docs/CONVENTIONS.md`, `docs/MODULES.md`, `docs/STATE.md`, `docs/GAME.md`, `docs/REVIEW_CHECKLIST.md`, `docs/specs/_TEMPLATE.md`
- Delete: `AGENTS.md` (after merging)

- [ ] **Step 1: `CLAUDE.md` (≤ 60 lines), a router:** 10-line repo map; workflow `spec → build → tools/check.sh → (reviewer if risky, per decision 5) → Catlyn playtests → feedback log → update STATE`; model routing (explorer=haiku, builder/world-builder/studio-tester=sonnet, reviewer=opus); rules: read `docs/MODULES.md` before searching code; never search the notes vault; never read whole Studio trees via MCP — query specific paths or tags; scenes change via `layout.luau`/`mood.luau`, never by hand-placing parts; run `tools/check.sh` before saying done; before changing anything with a spec, read every "Decided" line in its feedback log; run shell commands one at a time, never chained with `&&` or `;`.
- [ ] **Step 2: `docs/CONVENTIONS.md`:** strict Luau; one responsibility per ModuleScript; files under ~200 lines; typed public APIs; **pure logic in modules Lune can test, engine glue thin**; server validates every remote; CollectionService tags instead of hard-coded paths; naming rules; libraries come from Wally, never hand-rolled.
- [ ] **Step 3: `docs/MODULES.md`:** table `path | purpose | public API`, one line per module; fill it by scanning `src/` (include the Task 3–5 modules).
- [ ] **Step 4: `docs/GAME.md`:** merge game-specific content from `AGENTS.md` (content rules, story constraints, tone). Note at the top: "Source of truth for agents. Excerpted from Catlyn's vault; do not look for the vault." Milestones go to `docs/STATE.md` (≤ 40 lines: milestone, done, next, known issues). Delete `AGENTS.md`.
- [ ] **Step 5: `docs/specs/_TEMPLATE.md`:** goal; files touched; API; edge cases; acceptance checks (each marked `[lune]` or `[playtest]`); out of scope; and:

```markdown
## Feedback log
<!-- Newest round last. Builders read every "Decided" line before changing anything. -->
### Round 1 — YYYY-MM-DD
- Catlyn said:
- Decided:
```

- [ ] **Step 6: `docs/REVIEW_CHECKLIST.md`:** server validation and rate limits on remotes; no client trust; connections cleaned up; tags not paths; types on public APIs; mobile perf (part count, per-frame work); spec feedback-log decisions respected.
- [ ] **Step 7:** `wc -l CLAUDE.md docs/STATE.md` → expected ≤ 60 and ≤ 40. `tools/check.sh` → `OK`.
- [ ] **Step 8:** Commit: `git commit -m "docs: lean CLAUDE.md router and project docs"`.

---

### Task 7: Subagents with fixed models

**Files:**
- Create/replace in `.claude/agents/`: `explorer.md`, `builder.md`, `reviewer.md`, `studio-tester.md`, `world-builder.md`, `story-keeper.md`
- Remove from `.claude/agents/`: any old agents not listed here (move `sound-designer` and `voice-over` to `docs/archive/agents/` until needed — *Claude's call: fewer agent descriptions loaded per turn*)

Each file: frontmatter `name`, `description` (one sentence on when to use it), minimal `tools`, `model`.

- [ ] **Step 1:** `explorer` — haiku; Read, Grep, Glob. Answers "where/how does X work" in ≤ 15 lines with paths; never pastes whole files.
- [ ] **Step 2:** `builder` — sonnet; Read, Edit, Write, Bash. Implements one spec; touches only the files it lists; reads the feedback log first; runs `tools/check.sh` until `OK`; updates `docs/MODULES.md`.
- [ ] **Step 3:** `reviewer` — opus; Read, Grep, Bash(`git diff*`). Reviews diff against spec + `docs/REVIEW_CHECKLIST.md`; returns `PASS` or a numbered list. Description states it's only for remotes, DataStore, client-trust, or diffs over ~150 lines.
- [ ] **Step 4:** `studio-tester` — sonnet; the **only** agent with Studio MCP tools. Runs `[playtest]` acceptance checks using console output; takes a screenshot only when the spec or Catlyn asks; returns pass/fail per check.
- [ ] **Step 5:** `world-builder` — sonnet; Read, Edit, Write, Bash. Changes scenes **only** by editing `layout.luau`/`mood.luau`; when a needed piece doesn't exist, it stops and proposes a new prefab (name + one-line description) instead of building geometry inline.
- [ ] **Step 6:** `story-keeper` — haiku; Read, Grep. Checks content against `docs/GAME.md`; returns conflicts only.
- [ ] **Step 7:** Check `wc -l .claude/agents/*.md` → each ≤ 40. Commit: `git commit -m "chore: subagents with fixed models"`.

---

### Task 8: Skills for repeated jobs

**Files:** `.claude/skills/<name>/SKILL.md` for each skill below (frontmatter `name` + `description`; ≤ 50 lines of steps; each points to one golden example file).

- [ ] **Step 1:** `new-feature` — copy the spec template, fill it in *with Catlyn*, send to `builder`, run `reviewer` only if decision 5 applies, `studio-tester` for `[playtest]` checks, update `docs/STATE.md`. Golden example: `src/server/SceneLoader.luau` + `tests/scene.spec.luau` (pure logic + thin glue).
- [ ] **Step 2:** `iterate` — Catlyn gives feedback on a prototype: append a new Round to the spec's feedback log (her words + "Decided" lines), confirm the decisions back to her in ≤ 3 lines, then hand only the delta to `builder` or `world-builder`. Never re-plan the whole feature.
- [ ] **Step 3:** `edit-scene` — map Catlyn's request to layout/mood edits via `world-builder`; run `tools/check.sh`; tell her to playtest; log the round. Golden example: `src/server/Scenes/village/`.
- [ ] **Step 4:** `new-prefab` — agree name + purpose; build it in Studio inside `Workspace.PrefabWorkshop` (Catlyn or `studio-tester` via MCP); Catlyn saves to `work/workshop.rbxl`; run `lune run tools/extract-prefabs work/workshop.rbxl`; commit the `.rbxm`. Golden example: `tools/extract-prefabs.luau`.
- [ ] **Step 5:** `fix-bug` — reproduce → failing Lune test (or a written `[playtest]` repro if it's engine glue) → fix → `tools/check.sh`. No fixes without a repro.
- [ ] **Step 6:** Commit: `git commit -m "chore: skills for features, iteration, scenes, prefabs, bugs"`.

---

### Task 9: Test run and comparison (Catlyn + Claude Code)

- [ ] **Step 1:** Run one small real feature through `/new-feature` and one village change through `/edit-scene` plus at least one `/iterate` round.
- [ ] **Step 2:** Record `/context` midway and `/cost` at the end next to the Task 0 numbers in `docs/BASELINE.md`.
- [ ] **Step 3:** Ask: *"Looking at this session, what in CLAUDE.md, the skills or the agents caused wasted tokens or rework? Propose specific cuts."* Apply the cuts you agree with.
- [ ] **Step 4:** Commit: `git commit -m "chore: first refinement pass after measurement"`. Repeat Steps 1–4 every few features.