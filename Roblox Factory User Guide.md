# Roblox Factory User Guide

Nov 17, 2026 · @catlyn

## How the factory works

You say what you want, agents build it, automatic checks catch mechanical mistakes, and you judge the result by playing it. Your feedback is written into a file, so it survives `/clear` and new sessions.

Every kind of thing in the game has one home and one owner:

| Thing | Where it lives | Who changes it |
| --- | --- | --- |
| Code | `src/` | builder agent |
| Reusable pieces (prefabs) | `assets/prefabs/*.rbxm` | you build in Studio; a tool extracts them |
| Where pieces are placed | `src/server/Scenes/<scene>/layout.luau` | world-builder agent |
| Lighting, fog, atmosphere | `src/server/Scenes/<scene>/mood.luau` | world-builder agent |
| Graybox ground and paths | `src/server/World/Build.luau` | builder agent, rarely |
| Story and game rules agents follow | `docs/GAME.md` | you |
| Where the project stands | `docs/STATE.md` | updated at the end of every job |
| Your feedback per feature or scene | `docs/specs/<name>.md`, Feedback log | `/iterate` and `/edit-scene` |

The loop for any job:

1. You start a command and describe the job.
2. Agents build it and run `tools/check.sh` until it prints `OK`.
3. You playtest in Studio.
4. You give feedback with `/iterate`. It is logged as "Decided" lines that later agents must follow.
5. Repeat 2–4 until you're happy. The job ends with the finish routine: update STATE, log decisions and issues, commit.

The rule behind all of it: build pieces once, then iterate on how they're combined. Small text edits are cheap; regenerating things is expensive.

## Starting a session

Open one session per job, start it with one line, and type `/clear` when the job is done.

1. If the job touches anything you'll look at in Studio, run `rojo serve` in the mada folder and click **Plugins → Rojo → Connect** in Studio.
2. Run `claude` in the mada folder. Press Shift+Tab until it shows auto-accept edits.
3. Pick the model and effort for the job (table below).
4. Start with: `Read docs/STATE.md, then /<command> <what you want>`. Don't re-explain the project: the docs already do.
5. When the job is finished and committed, type `/clear` before the next one.

| Job | Model | Effort |
| --- | --- | --- |
| Most commands | Sonnet | medium |
| Tricky engine or tooling work, or a job stuck failing the same check | Sonnet | high |
| Questions, doc fixes, small cleanups | Sonnet | low |
| A review of a whole branch every few weeks | Opus | medium |

## The five commands

Pick the command by what you're doing: making something new, reacting to something you played, moving things in the world, making a new piece, or fixing something broken.

| Command | Use it when | You get |
| --- | --- | --- |
| `/new-feature` | You want new gameplay or code | A spec, working code, checks passed, ready to playtest |
| `/iterate` | You played a prototype and want changes | Your feedback logged, and only the change built |
| `/edit-scene` | You want to move, add or remove placed pieces, or change the mood | Edited `layout.luau` or `mood.luau` |
| `/new-prefab` | You need a reusable piece that doesn't exist yet | A versioned `.rbxm` in `assets/prefabs/` |
| `/fix-bug` | Something is broken | A reproduction, a fix, checks passed |

These describe the commands as designed in the factory plan. If one behaves differently, the file in `.claude/skills/<name>/SKILL.md` is the source of truth.

### /new-feature

It fills in a spec with you, then builds from it. Answer its questions; they set the goal, the acceptance checks and what's out of scope.

- **What happens:** builder writes the code and runs `check.sh`. The reviewer (Opus) runs only for networking, saved data, anything trusting the client, or changes over about 150 lines. studio-tester runs the playtest checks.
- **Your part:** answer the spec questions, then playtest.
- **Example:** `/new-feature lanterns flicker when the player is within 10 studs, and go steady when they leave`

### /iterate

Use it after every playtest where you want something changed. It writes your words and the decisions into the spec's Feedback log, confirms them back in three lines or fewer, and sends only the change to an agent.

- **Your part:** read the three-line confirmation. If a "Decided" line is wrong, correct it now: future agents follow those lines.
- **Tip:** give one round of feedback at a time, covering everything you noticed in that playtest.
- **Example:** `/iterate lanterns: flicker is too fast, about half the speed; keep the radius`

### /edit-scene

It changes where things are and how the scene looks, by editing `layout.luau` and `mood.luau`. It never places parts by hand. If a piece you ask for doesn't exist, it stops and proposes a new prefab instead of improvising one.

- **Your part:** playtest after, then `/iterate` if needed.
- **Example:** `/edit-scene village: move the shrine 6 studs toward the lake, add 2 lanterns on either side of the path, fog a bit thicker`

### /new-prefab

It makes a new reusable piece. You agree on a name and purpose. Then you (or the main session through Studio MCP) build it in Studio inside `Workspace.PrefabWorkshop`, and save the place as `work/workshop.rbxl`. The command runs the extraction tool and commits the `.rbxm`; studio-tester only verifies.

- **Your part:** the building in Studio, and **File → Save to File As…** into `work/`.
- **Naming:** letters, digits and `_`, starting with a letter. Variants go `StiltHouse_A`, `StiltHouse_B`. Names differing only by case count as the same name.
- **Example:** `/new-prefab StiltHouse_A: small stilt house on 4 posts, one door facing the water`

### /fix-bug

It reproduces the bug first, writes a failing test (or a written playtest repro for engine code), then fixes it. It won't guess at a fix without a repro.

- **Your part:** say what you did, what happened, what you expected, and paste any red lines from the Output panel.
- **Example:** `/fix-bug pressing Skip during the intro dialogue does nothing; Output shows no error`

## Who does the work

The commands call six agents for you. You rarely need to call one directly, but knowing who does what tells you what to expect.

| Agent | Model | Does | Can't |
| --- | --- | --- | --- |
| explorer | Haiku | Finds where and how something works, in 15 lines or fewer | Edit anything |
| builder | Sonnet | Builds one spec, runs `check.sh` until OK, updates `docs/MODULES.md` | Touch files the spec doesn't list |
| world-builder | Sonnet | Edits `layout.luau` and `mood.luau`, lists existing prefabs | Build geometry by hand |
| reviewer | Opus | Reviews risky changes against the spec and checklist | Edit anything; it runs only for networking, saved data, client trust, or big diffs |
| studio-tester | Sonnet | Runs playtests, reads the console, takes screenshots when asked | Change the place (it observes only) |
| story-keeper | Haiku | Checks content against `docs/GAME.md` | Write story text |

To ask a question directly, name the agent: `ask explorer where player spawning is handled`.

## Using it well

Specific requests cost fewer tokens and need fewer rounds. Vague ones make agents guess, and guesses get redone.

| Instead of | Say |
| --- | --- |
| make it creepier | fog end from 160 to 120, lanterns half as bright, a patch of reeds at the shore |
| fix the UI | the Skip button does nothing when pressed during the intro dialogue |
| add some houses | add 3 StiltHouse\_A along the north shore, 20 studs apart, facing the lake |
| make the ghost better | the ghost should pause 2 seconds before chasing, and stop at the shrine |

Habits that keep each job cheap:

- **One job per session, then `/clear`.** Long sessions drag old context into every reply.
- **Start from `docs/STATE.md`.** Never re-explain the project.
- **Keep your notes vault out.** Paste only the relevant lines into `docs/GAME.md` or the spec.
- **Playtest yourself.** Agent screenshots are among the most expensive things in the pipeline; ask for one only when you can't check it yourself.
- **Run `tools/check.sh` yourself** when you want to know if things are OK. It costs no tokens.
- **Correct "Decided" lines right away** in `/iterate`. A wrong decision gets followed in every later round.
- **Measure.** Run `/context` halfway and `/cost` at the end of a job, and add both to `docs/BASELINE.md`.
- **Every few features, ask:** "Looking at this session, what in CLAUDE.md, the skills or the agents caused wasted tokens or rework? Propose specific cuts."

## When something goes wrong

Most problems so far came from tools being out of sync, not from the game. Check this table before asking an agent to investigate.

| What you see | Likely cause | Fix |
| --- | --- | --- |
| `rojo serve` crashes with a Tags or SharedString error | Rojo is older than Studio | Raise the Rojo version in `rokit.toml`, run `rokit install`, then `rojo plugin install` and restart Studio |
| `check.sh` says a tool is missing | rokit tools not installed on this machine | `rokit install` |
| `check.sh` passes but says a file has fewer type errors than its baseline | You improved an old file | Lower that file's number in `tools/type-baseline.txt` |
| `check.sh` fails because a file has more type errors than its baseline | A change added a type error | Fix the new error; never raise the baseline |
| An agent says it can't see Studio MCP tools | Claude Code isn't connected to Studio | Studio Assistant → three dots → Manage MCP Servers → Quick connect Claude Code; restart Claude Code; check `claude mcp list` |
| A prefab doesn't show under ServerStorage → Prefabs | File not in `assets/prefabs/`, or Rojo didn't pick it up | `ls assets/prefabs`; restart `rojo serve`, then Disconnect and Connect in Studio |
| A command is "blocked by auto mode" or "permission denied" | The agent chained commands, or touched a protected path | Ask it to run commands one at a time; protected paths are intentional |
| Lighting looks wrong | Something other than `mood.luau` set it | `grep -rn "Lighting" src`; only SceneLoader should set base lighting |
| An agent undoes earlier feedback | The feedback never made it into a Feedback log | Use `/iterate`, and check its "Decided" lines |

## Quick reference

```
START     rojo serve  →  Studio: Plugins → Rojo → Connect
          claude  (auto-accept edits, Sonnet, medium)
          Read docs/STATE.md, then /<command> <what you want>

NEW       /new-feature <what it should do>
REACT     /iterate <what you saw, what you want instead>
MOVE      /edit-scene <scene>: <what goes where, mood changes>
PIECE     /new-prefab <Name>: <what it is>
BROKEN    /fix-bug <did, happened, expected, Output errors>

CHECK     tools/check.sh          (free; should print OK)
MEASURE   /context halfway, /cost at the end → docs/BASELINE.md
END       /clear
```
