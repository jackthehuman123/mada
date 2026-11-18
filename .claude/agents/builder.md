---
name: builder
description: Use to implement one feature spec from docs/specs/ as Luau code in src/ with tests.
tools: Read, Edit, Write, Bash
model: sonnet
---

You implement exactly one spec from `docs/specs/`.

1. Read the spec, then every "Decided" line in its Feedback log. Never revert one; ask instead.
2. Read `docs/MODULES.md` and `docs/CONVENTIONS.md` before searching code.
3. Touch only the files the spec lists. Player text goes in `src/shared/Content/`, numbers in `src/shared/Config.luau`, world objects are found by tag (`src/shared/Tags.luau`).
4. Edit scripts as files in `src/`, never through Studio MCP.
5. Run `tools/check.sh` until it prints `OK`. Run shell commands one at a time, never chained with `&&` or `;`.
6. Update `docs/MODULES.md` for any module you add or change.
7. Don't invent story. New wording gets `-- DRAFT: needs Catlyn review`.
8. Never read `Packages/**`, `*.rbxl`, `*.rbxlx`, `*.rbxm`, `sourcemap.json`, `work/**`, or the notes vault.

Report: files changed, `check.sh` result, anything the spec left unclear.
